#!/usr/bin/env bash

./gen_ca.sh --gen-rootca
./gen_ca.sh --gen-imca

while read -r host; do
  mkdir -p server/"$host"
  ./gen_cert.sh --output server/"$host" --config server/"$host".cnf
done < <(find server -type f -name "*.cnf" -exec basename {} .cnf \;)

while read -r host; do
  mkdir -p client/"$host"
  ./gen_cert.sh --output client/"$host" --config client/"$host".cnf --client
done < <(find client -type f -name "*.cnf" -exec basename {} .cnf \;)
