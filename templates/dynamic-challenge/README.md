# CVE-XXXX-XXXXX — <문제 이름>

## 배포 정보

| 항목 | 값 |
|---|---|
| 분류 | **동적** (RCE / 권한 상승 / 파일 쓰기) |
| 이미지 이름 | `chal/CHANGE_ME:v1` |
| 내부 포트 | `8080/tcp` |
| 메모리 | `256MB` |
| 네트워크 | `Isolated` (실행 중 외부 다운로드 없음) |
| 아키텍처 | ARM64 빌드 확인 ☐ / x86 전용 ☐ (x86 전용이면 사유 기재 후 운영진에게 미리 알림) |
| 플래그 템플릿 | `WINS{[GUID]}` |

## 빌드 & 로컬 검수

```bash
docker build -t chal/CHANGE_ME:v1 .
FLAG='WINS{local_test}' docker compose up -d --build
# exploit 실행 → WINS{local_test} 획득 확인
docker compose down
```

## 제작자 체크리스트 (4차 공지)

- [ ] 플래그는 `GZCTF_FLAG`와 `FLAG` 둘 다 대응 (하드코딩 금지)
- [ ] 권한 상승 문제: root로 `/flag` 기록 → `unset` → 저권한 사용자로 전환
- [ ] ARM(Ampere)에서 빌드 확인
- [ ] 고정 `container_name`·고정 포트 없음 (compose는 로컬 검수용)
- [ ] 메모리 256MB 이내, 외부 인터넷 없이 동작
- [ ] 커널 취약점 문제 아님
- [ ] privileged·docker.sock·호스트 마운트 없음
