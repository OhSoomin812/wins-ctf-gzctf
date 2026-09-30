#!/bin/sh
# 여기에 실제 취약 서비스 실행 명령을 넣으세요 (appuser 권한으로 실행됨).
# 아래는 동작 확인용 더미 웹서버입니다.
mkdir -p /tmp/www && echo "hello from challenge" > /tmp/www/index.html
exec httpd -f -p 8080 -h /tmp/www
