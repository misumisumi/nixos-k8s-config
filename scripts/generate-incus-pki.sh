#!/usr/bin/env bash
set -euo pipefail
usage() {
  cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(
    basename "${BASH_SOURCE[0]}"
  ) [-o|--output OUTPUT] [-c|--cnf-file CNF_FILE] [--days-ca DAYS_CA] [--days-cert DAYS_CERT] [--client-only]

Generate PKI certificates for Incus API.

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
  WORKDIR=".pki/incus"
  CNF_FILE=""
  DAYS_CA=3650   # 10 years for CA
  DAYS_CERT=1825 # 5 years for server/client certificates
  CLIENT_ONLY=0
  while (($# > 0)); do
    count=$((count + 1))
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    -o | --output)
      WORKDIR="${2-}"
      shift
      ;;
    -c | --cnf-file)
      CNF_FILE="${2-}"
      shift
      ;;
    --days-ca)
      DAYS_CA="${2-}"
      shift
      ;;
    --days-cert)
      DAYS_CERT="${2-}"
      shift
      ;;
    --client-only)
      CLIENT_ONLY=1
      ;;
    --)
      break
      ;;
    esac
    shift
  done

  count="$((count + 1))"
  return 0
}

parse_params "$@"

if [ -z "${CNF_FILE}" ]; then
  CNF_FILE="${WORKDIR}/openssl.cnf"
fi

ROOT_CA_DIR="${WORKDIR}/root-ca"
CLIENT_CA_DIR="${WORKDIR}/client-ca"
mkdir -p "${ROOT_CA_DIR}" "${CLIENT_CA_DIR}"

# CA certificate
C="JP"               # Country
ST="Tokyo"           # State of Province
L="Tokyo"            # Locality
O="Project-Cardinal" # Organization
OU="Incus"           # Organizational Unit
# Create openssl config
if [ ! -f "${CNF_FILE}" ]; then
  echo "${CNF_FILE} does not exist. Creating a new one."
  cat >"${CNF_FILE}" <<'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./root-ca
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
private_key       = $dir/root-ca.key
certificate       = $dir/root-ca.crt

default_md        = sha256
default_days      = 3650 # 10 years
preserve          = no
policy            = policy_loose

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @server_alt_names

[ server_alt_names ]
IP.1 = 172.16.10.50

[ client_cert ]
basicConstraints = CA:FALSE
nsCertType = client
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== PKI Certificate Generation ===${NC}"

# Create certificate directory
echo -e "${GREEN}[1/5] Generating Root CA certificate...${NC}"

ROOT_CA_KEY="${ROOT_CA_DIR}/root-ca.key"
ROOT_CA_CERT="${ROOT_CA_DIR}/root-ca.crt"
CN="Incus-Root-CA" # Common Name
# CA private key (楕円曲線暗号)
openssl ecparam -name secp384r1 -genkey -noout -out "${ROOT_CA_KEY}"
# CA private key (RSA暗号)
# openssl genpkey -algorithm RSA -out ca.key -pkeyopt rsa_keygen_bits:4096
openssl req -new -x509 -sha256 -key "${ROOT_CA_KEY}" -out "${ROOT_CA_CERT}" -days "${DAYS_CA}" \
  -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}"

# Generate client certificate
echo -e "${GREEN}[3/5] Generating client certificate...${NC}"

CLIENT_CA_KEY="${CLIENT_CA_DIR}/client.key"
CLIENT_CA_CSR="${CLIENT_CA_DIR}/client.csr"
CLIENT_CA_CERT="${CLIENT_CA_DIR}/client.crt"
CN="Incus-Client" # Common Name

openssl ecparam -name secp384r1 -genkey -noout -out "${CLIENT_CA_KEY}"
# openssl genpkey -algorithm RSA -out client.key -pkeyopt rsa_keygen_bits:2048
openssl req -new -sha256 -key "${CLIENT_CA_KEY}" -out "${CLIENT_CA_CSR}" \
  -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}"
openssl x509 -req -days "${DAYS_CERT}" \
  -in "${CLIENT_CA_CSR}" \
  -CA "${ROOT_CA_CERT}" \
  -CAkey "${ROOT_CA_KEY}" \
  -CAcreateserial \
  -out "${CLIENT_CA_CERT}" \
  -extensions client_cert \
  -extfile "${CNF_FILE}"

# Generate server certificate
echo -e "${GREEN}[3/5] Generating server certificate...${NC}"
if [ "${CLIENT_ONLY}" -eq 1 ]; then
  echo -e "${GREEN}    Skipping server certificate generation as --client-only is set.${NC}"
else
  SERVER_CA_DIR="${WORKDIR}/server-ca"
  mkdir -p "${SERVER_CA_DIR}"
  SERVER_CA_KEY="${SERVER_CA_DIR}/server.key"
  SERVER_CA_CSR="${SERVER_CA_DIR}/server.csr"
  SERVER_CA_CERT="${SERVER_CA_DIR}/server.crt"
  CN="Incus-Server" # Common Name
  openssl ecparam -name secp384r1 -genkey -noout -out "${SERVER_CA_KEY}"
  # openssl genpkey -algorithm RSA -out server.key -pkeyopt rsa_keygen_bits:2048
  openssl req -new -sha256 -key "${SERVER_CA_KEY}" -out "${SERVER_CA_CSR}" \
    -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}"
  openssl x509 -req -days "${DAYS_CERT}" \
    -in "${SERVER_CA_CSR}" \
    -CA "${ROOT_CA_CERT}" \
    -CAkey "${ROOT_CA_KEY}" \
    -CAcreateserial \
    -out "${SERVER_CA_CERT}" \
    -extensions server_cert \
    -extfile "${CNF_FILE}"
fi

echo -e "${GREEN}[4/5] Creating server.ca and client.ca files...${NC}"
cp "${ROOT_CA_CERT}" "${CLIENT_CA_DIR}/client.ca"
if [ "${CLIENT_ONLY}" -eq 0 ]; then
  cp "${ROOT_CA_CERT}" "${SERVER_CA_DIR}/server.ca"
fi

echo -e "${GREEN}[5/5] PKI certificates check${NC}"

openssl x509 -noout -text -in "${ROOT_CA_CERT}"
openssl verify -CAfile "${ROOT_CA_CERT}" "${CLIENT_CA_CERT}"
if [ "${CLIENT_ONLY}" -eq 0 ]; then
  openssl verify -CAfile "${ROOT_CA_CERT}" "${SERVER_CA_CERT}"
fi

echo -e "${BLUE}=== PKI Certificate Generation Completed ===${NC}"
