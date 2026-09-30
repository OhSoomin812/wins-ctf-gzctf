#!/bin/sh
# GZCTF DB 백업 (pg_dump). cron 예시는 crontab.example 참고.
# 사용: host/backup.sh [보관일수=7]
set -eu
cd "$(dirname "$0")/.."
KEEP_DAYS="${1:-7}"
mkdir -p backups
out="backups/gzctf-$(date +%Y%m%d-%H%M%S).sql.gz"
docker compose exec -T db pg_dump -U postgres gzctf | gzip > "$out"
find backups -name 'gzctf-*.sql.gz' -mtime +"$KEEP_DAYS" -delete
echo "[✓] $out"
# 복구: gunzip -c <파일> | docker compose exec -T db psql -U postgres gzctf
