#!/bin/sh
# GZCTF 첫 기동 "전에" 실행. 인스턴스 간 통신(icc)을 끈 문제 네트워크를 미리 만든다.
# GZCTF는 이 이름의 네트워크가 이미 있으면 새로 만들지 않고 그대로 사용한다.
# 이미 GZCTF를 띄운 적이 있다면: docker compose down → 기존 네트워크 삭제 → 이 스크립트 → 재기동
set -eu

create() {
  name="$1"; shift
  if docker network inspect "$name" >/dev/null 2>&1; then
    icc=$(docker network inspect -f '{{index .Options "com.docker.network.bridge.enable_icc"}}' "$name")
    if [ "$icc" != "false" ]; then
      echo "[!] $name 이 icc 활성 상태로 이미 존재합니다. 연결된 컨테이너를 정리한 뒤 'docker network rm $name' 후 다시 실행하세요." >&2
      exit 1
    fi
    echo "[=] $name 이미 존재 (icc=false)"
  else
    docker network create -d bridge --attachable -o com.docker.network.bridge.enable_icc=false "$@" "$name"
    echo "[+] $name 생성"
  fi
}

# Open: 외부 인터넷 허용
create gzctf-open
# Isolated: 외부 인터넷 차단 (포트 매핑은 동작)
create gzctf-isolated -o com.docker.network.bridge.enable_ip_masquerade=false
