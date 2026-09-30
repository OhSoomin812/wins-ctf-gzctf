# WINS CTF — GZCTF 플랫폼 세팅

윈스테크넷 9기 CTF를 **GZCTF v1.8.7 + 동적 컨테이너** 방식으로 운영하기 위한 배포 레포입니다.
기준 문서: Notion「CTF 페이지 4차 공지: 동적 컨테이너 방식」 / 참고: [Minseo9503/gzctf-deploy](https://github.com/Minseo9503/gzctf-deploy)

> **한 줄 요약:** VM 한 대에 GZCTF 플랫폼이 항상 켜져 있고, 문제 컨테이너는 참가자가 "인스턴스 시작"을 누를 때만 그 사람 전용으로 생겼다 사라집니다.

## 확정 사항

| 항목 | 결정 |
|---|---|
| 플랫폼 | GZCTF v1.8.7 (공식 이미지, 소스 수정 없음) |
| 서버 | OCI Always Free Ampere A1 VM 1대 (4 OCPU, 24GB, **ARM**) |
| 대회 기간 | 1주일 |
| 참가 인원 | 최대 25명 (개인전) |
| 인스턴스 정책 | 1인당 동시 1개, 수명 30분 (만료 10분 전부터 30분 연장 가능) |
| 플래그 | `WINS{[GUID]}` — 인스턴스마다 다른 값, `GZCTF_FLAG`로 주입 |

## 구성

```
.
├── docker-compose.yml      # gzctf + postgres (+ caddy: prod 프로필)
├── appsettings.json        # 플랫폼 설정 (비밀값 없음 — .env 가 덮어씀)
├── Caddyfile               # HTTPS 리버스프록시 → gzctf:8080
├── .env.example            # 시크릿 템플릿 → .env 로 복사
├── host/
│   ├── setup-networks.sh   # icc 끈 문제 네트워크 생성 (첫 기동 전 필수)
│   ├── firewall.sh         # OCI iptables 포트 개방 + 메타데이터 차단
│   ├── daemon.json         # 도커 로그 크기 제한 → /etc/docker/daemon.json
│   ├── backup.sh           # pg_dump 백업
│   ├── restart-shared.sh   # 공유 문제 주기 재시작
│   └── crontab.example
└── templates/
    ├── dynamic-challenge/  # 동적 문제 템플릿 (Dockerfile, entrypoint.sh, 검수용 compose, README)
    └── shared-challenge/   # 공유 문제용 compose (read_only, tmpfs, 재시작 라벨)
└── examples/
    └── test-cmdi/          # 플랫폼 점검용 RCE 테스트 문제 (명령어 주입)
```

## 빠른 시작 (로컬 테스트)

전제: Docker Desktop 또는 Docker Engine + compose.

```bash
cp .env.example .env        # DB_PASSWORD / GZCTF_ADMIN_PASSWORD / XOR_KEY 랜덤 값으로 채우기
sh host/setup-networks.sh   # 첫 기동 전 1회
docker compose up -d
```

- 웹 UI: <http://localhost:8080> — 아이디 `Admin`, 비번 = `.env`의 `GZCTF_ADMIN_PASSWORD`
- 종료: `docker compose down` (데이터 유지). 문제 등록 화면은 넓은 창이 필요합니다.
- 로컬에서 **문제 등록 → 인스턴스 시작 → 풀이 → 제출**까지 한 번 확인한 뒤 실서버로 올리세요.

## 실서버 배포 (OCI A1 VM)

### 1. VM / 네트워크
- Image: Ubuntu 22.04, Shape: **VM.Standard.A1.Flex (4 OCPU / 24GB)**, SSH 키 등록
- **OCI 보안 목록(Ingress)** 과 **호스트 iptables** 두 겹 모두 열어야 합니다.

| 포트 | 용도 | 개방 대상 |
|---|---|---|
| 22/tcp | SSH (키 인증만) | 운영진 IP |
| 80, 443/tcp | Caddy → GZCTF (HTTPS) | 전체 |
| 10000–19999/tcp | 공유 문제 | 전체 |
| 32768–60999/tcp | 동적 인스턴스 | 전체 |

### 2. 설치 & 기동
```bash
# 커널·패키지 최신화 후 재부팅 (컨테이너 탈출 대비)
sudo apt update && sudo apt full-upgrade -y && sudo reboot

curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER            # 재로그인
sudo cp host/daemon.json /etc/docker/daemon.json && sudo systemctl restart docker

git clone <이 레포> gzctf && cd gzctf
cp .env.example .env                     # 시크릿 + PUBLIC_ENTRY(공인 IP/도메인) + DOMAIN
sh host/setup-networks.sh                # ⚠️ GZCTF 첫 기동 전에
sudo sh host/firewall.sh                 # 포트 개방 + 169.254.169.254 차단 + 저장
docker compose --profile prod up -d      # gzctf + db + caddy
crontab -e                               # host/crontab.example 참고 (백업·공유 문제 재시작)
```

- `PUBLIC_ENTRY`가 참가자에게 보이는 접속 주소(`nc <PUBLIC_ENTRY> 32xxx`)입니다. localhost로 두면 참가자가 접속하지 못합니다.
- `DOMAIN`의 DNS A 레코드가 VM 공인 IP를 가리켜야 Caddy가 인증서를 받습니다.
- GZCTF는 `127.0.0.1:8080`에만 바인딩되어 Caddy만 접근합니다. 문제 컨테이너에서도 8080에 닿지 않습니다.

## GZCTF 관리자 설정값

사이트 제목과 수명 관련 값은 `appsettings.json`이 아니라 **관리자 화면(DB)** 에서 설정해야 적용됩니다.

| 설정 위치 | 항목 | 값 |
|---|---|---|
| 관리자 → 설정 → 전역 설정 | 사이트 제목 | WINS CTF |
| 관리자 → 설정 → 컨테이너 정책 | 기본 수명 | 30분 |
| 관리자 → 설정 → 컨테이너 정책 | 연장 시간 | 30분 |
| 관리자 → 설정 → 컨테이너 정책 | 갱신 가능 구간 | 만료 10분 전부터 |
| 게임 설정 | 팀당 컨테이너 수 | 1 (기본값 3) |
| 게임 설정 | 팀 인원 제한 | 1 (개인전) |
| 문제 설정 | 메모리 제한 | 256MB (기본값 64MB) |
| 문제 설정 | 네트워크 모드 | Isolated (외부 인터넷 차단) |
| 문제 설정 | 플래그 템플릿 | `WINS{[GUID]}` |

CPU 제한은 리눅스에서 사실상 적용되지 않으므로 대회 중 `docker stats`로 확인합니다.

## 문제 등록

### 공유 vs 동적 분류

참가자가 **서버 상태를 바꾸거나 망가뜨릴 수 있으면 동적**, 읽기만 하면 공유입니다.

| 문제 유형 | 예시 | 배포 |
|---|---|---|
| 원격 코드 실행 | 명령어 주입, 역직렬화, 업로드 웹셸 | 동적 |
| 권한 상승 | SUID, sudo 설정 오류 | 동적 |
| 파일 쓰기·변조 | 임의 파일 쓰기, 설정 덮어쓰기 | 동적 |
| 정보 노출 | SQLi(조회), 경로 탐색, SSRF 조회 | 공유 |
| 인증 우회 | JWT 위조, 세션 조작 | 공유 |

커널 취약점 문제는 호스트 커널을 공유하므로 제외합니다.

### 동적 문제
1. 같은 VM에서 이미지 빌드 (레지스트리 불필요):
   ```bash
   git clone <문제 레포> && cd <문제 레포>
   docker build -t chal/<이름>:v1 .
   ```
2. Admin → 게임 생성 → 문제 추가 → 유형 **동적 컨테이너**
3. 문제 README의 **배포 정보** 블록(이미지, 내부 포트, 메모리)과 위 설정값을 입력 후 활성화

### 공유 문제
`templates/shared-challenge/docker-compose.yml` 기준으로 1차 시트 배정 포트(10000–19999)에 상시 실행합니다.
`read_only: true`, `tmpfs: /tmp`, `wins.shared=true` 라벨(1시간마다 재시작)이 걸려 있습니다.

### 문제 제작자 체크리스트
새 문제는 `templates/dynamic-challenge/`를 복사해 시작하세요.

- [ ] 플래그 변수는 `GZCTF_FLAG`(대회)와 `FLAG`(로컬 검수) 둘 다 대응 — 하드코딩 금지
- [ ] 권한 상승 문제는 root로 `/flag` 기록 → `unset` → 저권한 사용자로 전환
- [ ] 서버는 **ARM(Ampere)** — ARM 빌드 확인. x86 전용이면 README에 명시하고 운영진에게 미리 알림
- [ ] compose는 로컬 검수용 — 고정 `container_name`·고정 포트는 공유 문제만
- [ ] README 첫머리에 **배포 정보** 블록 (이미지, 내부 포트, 메모리, 공유/동적)
- [ ] 메모리 256MB 이내, 외부 인터넷 없이 동작
- [ ] privileged · docker.sock · 호스트 마운트 금지

## 보안 메모
- **인스턴스 간 격리:** `host/setup-networks.sh`가 `gzctf-open`/`gzctf-isolated`를 `enable_icc=false`로 미리 생성합니다. GZCTF는 이 이름의 네트워크가 없을 때만 icc가 켜진 네트워크를 직접 만듭니다. 이미 띄웠다면 네트워크를 지우고 다시 생성하세요.
- **메타데이터 차단:** `DOCKER-USER` 체인에서 `169.254.169.254` DROP
- **자원 우선권:** gzctf·db에 `cpu_shares: 4096`, 도커 로그 10MB × 3개 제한
- **백업:** `host/backup.sh`를 cron으로 6시간마다 실행 (`backups/`, 7일 보관)
- `.env`와 `XOR_KEY`는 유출 시 플래그가 노출되니 저장소나 채팅에 올리지 마세요.

## 동작 확인 (서버에 올린 뒤)

로컬(Docker Desktop, 2026-09-30)에서 아래 항목을 확인했습니다.
플랫폼 기동, 인스턴스 생성, 포트 매핑(32768~), 인스턴스별 플래그 주입, 256MB 제한, 컨테이너 간 통신 차단(icc=false), 저권한 앱에서 플래그·환경변수 접근 불가.

**Isolated 네트워크의 외부 인터넷 차단은 Docker Desktop에서 적용되지 않아 확인하지 못했습니다.** 실서버(리눅스)에서 한 번 확인하세요.

```bash
# 관리자 화면에서 문제의 "테스트 컨테이너"를 띄운 뒤
C=$(docker ps --filter network=gzctf-isolated --format '{{.Names}}' | head -1)
docker exec "$C" wget -q -T 5 -O- http://example.com >/dev/null && echo "인터넷 됨(문제)" || echo "차단됨(OK)"
```

> ⚠️ 4차 공지 원문의 entrypoint 예시 `"${GZCTF_FLAG:-${FLAG:-WINS{placeholder}}}"` 는 플래그 끝에 `}`가 하나 더 붙는 버그가 있습니다.
> 이 레포의 `templates/dynamic-challenge/entrypoint.sh`처럼 기본값을 변수로 분리해 쓰세요.
