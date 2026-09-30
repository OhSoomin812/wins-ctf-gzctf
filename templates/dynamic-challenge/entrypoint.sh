#!/bin/sh
# entrypoint.sh: GZCTF_FLAG(대회) / FLAG(로컬 검수) 모두 대응
# FLAG_PATH: 기본 /flag. read_only 공유 문제는 /tmp/flag 처럼 tmpfs 경로 지정
# 주의: 기본값을 ${FLAG:-WINS{placeholder}} 처럼 직접 쓰면 중괄호가 잘못 짝지어져
#       플래그 끝에 '}' 가 하나 더 붙는다. 기본값은 반드시 변수로 분리할 것.
DEFAULT_FLAG='WINS{placeholder}'
FLAG_VALUE="${GZCTF_FLAG:-${FLAG:-$DEFAULT_FLAG}}"
FLAG_PATH="${FLAG_PATH:-/flag}"
echo "$FLAG_VALUE" > "$FLAG_PATH"
# 권한 상승 문제: 400 (root만 읽기) / RCE 문제: 444 (셸 획득 시 읽기 가능)
chown root:root "$FLAG_PATH" && chmod 400 "$FLAG_PATH"
# 저권한 앱이 /proc/self/environ 으로 플래그를 못 보게 환경변수 제거 후 권한 강등
unset GZCTF_FLAG FLAG FLAG_VALUE FLAG_PATH DEFAULT_FLAG
exec su-exec appuser /app/start.sh   # 또는 gosu
