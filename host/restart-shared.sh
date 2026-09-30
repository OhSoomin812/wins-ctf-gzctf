#!/bin/sh
# 공유 문제 컨테이너 주기 재시작 (흔적 제거). label wins.shared=true 인 컨테이너만 대상.
set -eu
ids=$(docker ps -q --filter label=wins.shared=true)
[ -n "$ids" ] && docker restart $ids >/dev/null && echo "[✓] restarted: $(echo $ids | wc -w)"
exit 0
