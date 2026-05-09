#!/usr/bin/env nix-shell
#!nix-shell -i bash -p openssl jq

set -euo pipefail
usage() {
  cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(
    basename "${BASH_SOURCE[0]}"
  ) [--gen-rootca] [--gen-imca] [--test]

Generate CA.

EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

check_in_host() {
  local json=$1
  local target=$2
  jq -r ".hosts[].name" "$json" | while read -r host; do
    if [ "${host}" == "${target}" ]; then
      return 0
    fi
  done
  return 1
}

parse_params() {
  # default values of variables set from params
  count=0
  CA_DIR=""
  TAG=""
  CURVE=""
  PASSWD=""
  while (($# > 0)); do
    count=$((count + 1))
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --gen-rootca)
      CA_DIR=RootCA
      TAG="Root CA"
      CURVE="secp384r1"
      ;;
    --gen-imca)
      CA_DIR=ImCA
      TAG="Intermediate CA"
      CURVE="prime256v1"
      ;;
    --test)
      PASSWD="test"
      ;;
    esac
    shift
  done

  count="$((count + 1))"
  return 0
}

parse_params "$@"

if [ -z "$CA_DIR" ]; then
  echo "Need to specify --gen-rootca or --gen-imca."
  exit 1
fi

if [ "$CA_DIR" == "ImCA" ] && [ ! -d "RootCA" ]; then
  echo "Run --gen-rootca before --gen-imca."
  exit 1
fi

if [ ! -z "$PASSWD" ]; then
  echo "Using test password."
else
  PASSWD=$(sops decrypt --extract '["rootca"]' ./passwd.yaml)
fi

FQDN="quintet.home"
C=JP
ST=Tokyo
O="Project Quintet"
OU="Project Quinted $TAG"
CN="${CA_DIR,,}.${FQDN}"

CA_CNF=ca.cnf
CA_KEY="$CA_DIR/private/cakey.pem"
CA_CSR="$CA_DIR/cacert.csr"
CA_CRT="$CA_DIR/cacert.crt"
CA_CHAIN="$CA_DIR/chain.pem"

if [ -d "$CA_DIR" ]; then
  echo "$CA_DIR already exists. Please remove it."
  exit 1
fi

mkdir -p "$CA_DIR"/{private,newcerts}
chmod 700 "$CA_DIR"/private

touch "$CA_DIR/index.txt"      # 署名履歴データベース
echo "01" >"$CA_DIR/serial"    # シリアル番号管理（初期値: 01）
echo "00" >"$CA_DIR/crlnumber" # CRL番号管理（初期値: 01）

if [ "$CA_DIR" == "RootCA" ]; then
  openssl ecparam -name "${CURVE}" -genkey -noout | openssl ec -aes256 -out "$CA_KEY" -passout pass:"$PASSWD"

  openssl req -new \
    -subj "/C=$C/ST=$ST/O=$O/OU=$OU/CN=$CN" \
    -key "$CA_KEY" \
    -passin pass:"$PASSWD" \
    -out "$CA_CSR"
else
  openssl ecparam -name "${CURVE}" -genkey -out "$CA_KEY"

  openssl req -new \
    -subj "/C=$C/ST=$ST/O=$O/OU=$OU/CN=$CN" \
    -key "$CA_KEY" \
    -out "$CA_CSR"
fi

openssl req -text -noout -in "$CA_CSR"

if [ "$CA_DIR" == "RootCA" ]; then
  echo "---------------------"
  echo "RootCA"
  echo "---------------------"
  CA_DIR="$CA_DIR" openssl ca -batch \
    -extensions v3_ca \
    -selfsign \
    -config "$CA_CNF" \
    -passin pass:"$PASSWD" \
    -in "$CA_CSR" \
    -out "$CA_CRT"
else
  echo "---------------------"
  echo "Intermediate"
  echo "---------------------"
  CA_DIR="$CA_DIR" openssl ca -batch \
    -extensions v3_ca \
    -config "$CA_CNF" \
    -cert RootCA/cacert.crt \
    -keyfile RootCA/private/cakey.pem \
    -passin pass:"$PASSWD" \
    -in "$CA_CSR" \
    -out "$CA_CRT"
fi

openssl x509 -text -in "$CA_CRT"

openssl x509 -in "$CA_CRT" -out "$CA_CRT"

if [ "$CA_DIR" == "ImCA" ]; then
  cat ImCA/cacert.crt RootCA/cacert.crt >"$CA_CHAIN"
fi
