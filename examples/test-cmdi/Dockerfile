# 테스트용 동적 문제: ping 기능 명령어 주입 (RCE)
FROM alpine:3.20
RUN apk add --no-cache su-exec busybox-extras \
 && adduser -D -H -s /sbin/nologin appuser
WORKDIR /app
COPY www /app/www
COPY start.sh /app/start.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /app/start.sh /entrypoint.sh /app/www/cgi-bin/ping
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
