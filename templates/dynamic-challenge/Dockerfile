# 동적 문제 템플릿 — ARM(Ampere)·x86 모두 빌드되는 베이스 이미지를 쓰세요.
FROM alpine:3.20

# su-exec: root → 저권한 사용자 전환 (debian 계열이면 gosu)
# busybox-extras: 더미 웹서버(httpd)용 — 실제 문제에선 필요한 패키지로 교체
RUN apk add --no-cache su-exec busybox-extras \
 && adduser -D -H -s /sbin/nologin appuser

WORKDIR /app
COPY start.sh /app/start.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /app/start.sh /entrypoint.sh

# 플래그는 이미지에 넣지 않는다. 런타임에 GZCTF_FLAG(대회) / FLAG(로컬) 로 주입됨
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
