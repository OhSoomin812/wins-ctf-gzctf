#!/bin/sh
# OCI Ubuntu 호스트 방화벽 설정 (sudo 로 실행). OCI 보안 목록(Security List)도 같은 포트를 따로 열어야 함.
# OCI Ubuntu 이미지는 ufw가 아니라 /etc/iptables/rules.v4 를 쓰며, INPUT 끝에 REJECT 규칙이 있다.
# 허용 규칙은 반드시 그 REJECT 보다 앞에 넣어야 한다.
set -eu

# INPUT 체인의 첫 REJECT 규칙 위치 (없으면 맨 끝에 추가)
pos=$(iptables -L INPUT --line-numbers -n | awk '$2=="REJECT"{print $1; exit}')

allow() {
  if iptables -C INPUT -p tcp -m state --state NEW --dport "$1" -j ACCEPT 2>/dev/null; then
    echo "[=] $1 이미 허용됨"; return
  fi
  if [ -n "$pos" ]; then
    iptables -I INPUT "$pos" -p tcp -m state --state NEW --dport "$1" -j ACCEPT
  else
    iptables -A INPUT -p tcp -m state --state NEW --dport "$1" -j ACCEPT
  fi
  echo "[+] $1 허용"
}

allow 80
allow 443
allow 10000:19999   # 공유 문제
allow 32768:60999   # 동적 인스턴스
# 22/tcp(SSH)는 OCI 기본 규칙으로 이미 열려 있음. 운영진 IP 제한은 OCI 보안 목록에서 설정.

# 컨테이너에서 OCI 메타데이터(인스턴스 정보·자격증명) 접근 차단
# DOCKER-USER 체인은 도커 데몬이 만들므로 도커 설치·기동 후 실행해야 함
if ! iptables -C DOCKER-USER -d 169.254.169.254 -j DROP 2>/dev/null; then
  iptables -I DOCKER-USER -d 169.254.169.254 -j DROP
  echo "[+] 메타데이터(169.254.169.254) 차단"
fi

netfilter-persistent save
echo "[✓] 저장 완료 (/etc/iptables/rules.v4)"
