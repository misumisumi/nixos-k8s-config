#!/usr/bin/env nix-shell
#!nix-shell -i bash -p openssl jq

set -euo pipefail
usage() {
  cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(
    basename "${BASH_SOURCE[0]}"
  ) [--output] [--client] [--config <config_file>]

Generate certificate.

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
  CERT_DIR=""
  CERT_CNF=""
  EXT="server_cert"
  SEC_REQ="server_req"
  while (($# > 0)); do
    count=$((count + 1))
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --output)
      CERT_DIR="${2-}"
      TAG="${CERT_DIR//\//_}"
      shift
      ;;
    --client)
      EXT="client_cert"
      SEC_REQ="client_req"
      ;;
    --config)
      CERT_CNF="${2-}"
      shift
      ;;
    esac
    shift
  done

  count="$((count + 1))"
  return 0
}

parse_params "$@"

if [ -z "$CERT_DIR" ]; then
  die "Output directory is required. Use --output <dir> to specify it."
fi

CERT_KEY="$CERT_DIR/private/cakey.pem"
CERT_CSR="$CERT_DIR/cacert.csr"
CERT_CRT="$CERT_DIR/cacert.crt"

mkdir -p "$CERT_DIR"/{private,newcerts}
chmod 700 "$CERT_DIR"/private

touch "$CERT_DIR/index.txt"      # 署名履歴データベース
echo "01" >"$CERT_DIR/serial"    # シリアル番号管理（初期値: 01）
echo "00" >"$CERT_DIR/crlnumber" # CRL番号管理（初期値: 01）

openssl ecparam -name prime256v1 -genkey -out "$CERT_KEY"

TAG="$TAG" openssl req -new \
  -config "$CERT_CNF" \
  -section "$SEC_REQ" \
  -batch \
  -key "$CERT_KEY" \
  -out "$CERT_CSR"

openssl req -text -noout -in "$CERT_CSR"

TAG="$TAG" \
  openssl ca -batch \
  -extensions "$EXT" \
  -config "$CERT_CNF" \
  -in "$CERT_CSR" \
  -out "$CERT_CRT"

openssl x509 -text -in "$CERT_CRT"
openssl x509 -in "$CERT_CRT" -out "$CERT_CRT"

echo "---------------------------------------"
echo "------Check the certificate chain------"
echo "---------------------------------------"

openssl verify -CAfile ImCA/chain.pem "$CERT_CRT"

cat "$CERT_CRT" ImCA/cacert.crt >"$CERT_DIR/chain.pem"

cat "$CERT_CRT" ImCA/chain.pem >"$CERT_DIR/full-chain.pem"
