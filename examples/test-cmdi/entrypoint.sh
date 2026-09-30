#!/bin/sh
# templates/dynamic-challenge/entrypoint.sh 와 동일. RCE 문제라 /flag 는 444 (셸 획득 시 읽기 가능)
DEFAULT_FLAG='WINS{placeholder}'
FLAG_VALUE="${GZCTF_FLAG:-${FLAG:-$DEFAULT_FLAG}}"
echo "$FLAG_VALUE" > /flag
chown root:root /flag && chmod 444 /flag
unset GZCTF_FLAG FLAG FLAG_VALUE DEFAULT_FLAG
exec su-exec appuser /app/start.sh
