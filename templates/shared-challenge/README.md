# 공유 문제 템플릿

동적 문제 템플릿(`../dynamic-challenge`)의 Dockerfile / entrypoint.sh / start.sh 를 그대로 쓰고,
`docker-compose.yml`만 이 파일로 교체합니다.

- `read_only: true` 이므로 쓰기는 `/tmp`(tmpfs)만 가능합니다. 플래그도 `FLAG_PATH=/tmp/flag`로 tmpfs에 기록됩니다.
- `wins.shared=true` 라벨이 붙은 컨테이너는 `host/restart-shared.sh`로 1시간마다 재시작됩니다.

## 배포 정보

| 항목 | 값 |
|---|---|
| 분류 | **공유** (정보 노출 / 인증 우회) |
| 이미지 이름 | `chal/CHANGE_ME:v1` |
| 외부 포트 | `CHAL_PORT` = 1차 시트 배정 포트 (10000–19999) |
| 내부 포트 | `8080/tcp` |
| 메모리 | `256MB` |
