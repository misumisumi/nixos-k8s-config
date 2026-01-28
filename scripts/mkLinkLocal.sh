#!/usr/bin/env bash

iid_hex=$(openssl rand -hex 8)
# U/L ビットをトグル（最初の 1 バイトを XOR 0x02）
first_byte="${iid_hex:0:2}"
first_flipped=$(printf '%02x' $((0x$first_byte ^ 0x02)))
# 再構成
iid="${first_flipped}${iid_hex:2}"
# IPv6 表記に整形
ll="fe80::${iid:0:4}:${iid:4:4}:${iid:8:4}:${iid:12:4}"
echo "$ll"
