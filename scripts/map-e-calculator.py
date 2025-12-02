#!/usr/bin/env python3
"""
MAP-E (RFC 7597) IPv4 Address and Port Calculator
IPv6プレフィックスからIPv4アドレスとポート範囲を計算

Usage:
    python map-e-calculator.py <ipv6_address_or_prefix> [--provider <provider_name>]
"""

import argparse
import ipaddress
import sys
from typing import Dict, List, Tuple


class MAPECalculator:
    """MAP-E パラメータ計算クラス"""

    # 主要プロバイダのMAP-Eルール
    PROVIDER_RULES = {
        "v6plus": {
            "name": "v6プラス (JPNE)",
            "br": "2404:8e00::feed:100",
            "ipv4_prefix": "240.0.0.0",
            "ipv4_prefix_len": 4,
            "ipv6_prefix": "2404:8e00::",
            "ipv6_prefix_len": 32,
            "ea_bits": 16,  # Embedded Address bits
            "psid_offset": 6,
            "psid_len": 4,
        },
        "ocn": {
            "name": "OCNバーチャルコネクト",
            "br": "2404:8e01::1",
            "ipv4_prefix": "153.254.0.0",
            "ipv4_prefix_len": 16,
            "ipv6_prefix": "2404:8e01::",
            "ipv6_prefix_len": 32,
            "ea_bits": 16,
            "psid_offset": 6,
            "psid_len": 4,
        },
        "transix": {
            "name": "transix (DS-Lite/MAP-E)",
            "br": "2404:8e00:feed:100::1",
            "ipv4_prefix": "106.72.0.0",
            "ipv4_prefix_len": 11,
            "ipv6_prefix": "2404:8e00::",
            "ipv6_prefix_len": 32,
            "ea_bits": 21,
            "psid_offset": 6,
            "psid_len": 4,
        },
    }

    def __init__(self, rule: Dict):
        """
        Args:
            rule: MAP-Eルール辞書
        """
        self.rule = rule
        self.ipv4_prefix = rule["ipv4_prefix"]
        self.ipv4_prefix_len = rule["ipv4_prefix_len"]
        self.ea_bits = rule["ea_bits"]
        self.psid_offset = rule["psid_offset"]
        self.psid_len = rule["psid_len"]

    def extract_ea_bits(self, ipv6_addr: str) -> int:
        """
        IPv6アドレスからEA (Embedded Address) bitsを抽出

        Args:
            ipv6_addr: IPv6アドレス文字列

        Returns:
            EA bits (整数)
        """
        addr = ipaddress.IPv6Address(ipv6_addr)
        addr_int = int(addr)

        # IPv6プレフィックス長の後からEA bitsを抽出
        ipv6_prefix_len = self.rule["ipv6_prefix_len"]

        # EA bitsの位置を計算
        shift = 128 - ipv6_prefix_len - self.ea_bits
        ea_mask = (1 << self.ea_bits) - 1
        ea_bits = (addr_int >> shift) & ea_mask

        return ea_bits

    def calculate_ipv4_address(self, ea_bits: int) -> str:
        """
        EA bitsからIPv4アドレスを計算

        Args:
            ea_bits: Embedded Address bits

        Returns:
            IPv4アドレス文字列
        """
        # IPv4プレフィックスを整数に変換
        ipv4_prefix = ipaddress.IPv4Address(self.ipv4_prefix)
        ipv4_prefix_int = int(ipv4_prefix)

        # IPv4サフィックスビット数
        ipv4_suffix_bits = 32 - self.ipv4_prefix_len

        # EA bitsからIPv4サフィックスとPSIDを分離
        ipv4_suffix = ea_bits >> self.psid_len

        # IPv4アドレスを構築
        ipv4_addr_int = (ipv4_prefix_int & ~((1 << ipv4_suffix_bits) - 1)) | ipv4_suffix
        ipv4_addr = ipaddress.IPv4Address(ipv4_addr_int)

        return str(ipv4_addr)

    def calculate_psid(self, ea_bits: int) -> int:
        """
        EA bitsからPSID (Port Set ID)を計算

        Args:
            ea_bits: Embedded Address bits

        Returns:
            PSID値
        """
        psid_mask = (1 << self.psid_len) - 1
        psid = ea_bits & psid_mask
        return psid

    def calculate_port_range(self, psid: int) -> Tuple[int, int]:
        """
        PSIDからポート範囲を計算

        Args:
            psid: Port Set ID

        Returns:
            (start_port, end_port) のタプル
        """
        # PSIDオフセットを考慮したポート計算
        # ポート範囲 = [PSID * 2^(16-psid_len-psid_offset), (PSID+1) * 2^(16-psid_len-psid_offset) - 1]

        ports_per_psid = 1 << (16 - self.psid_len - self.psid_offset)
        start_port = (1 << self.psid_offset) + (psid * ports_per_psid)
        end_port = start_port + ports_per_psid - 1

        return (start_port, end_port)

    def get_usable_port_ranges(self, psid: int) -> List[Tuple[int, int]]:
        """
        使用可能なポート範囲のリストを取得
        (Well-knownポート 0-1023 を除外)

        Args:
            psid: Port Set ID

        Returns:
            使用可能なポート範囲のリスト
        """
        start_port, end_port = self.calculate_port_range(psid)

        # Well-knownポート (0-1023) は通常使用不可
        if start_port < 1024:
            if end_port < 1024:
                return []
            return [(1024, end_port)]

        return [(start_port, end_port)]

    def calculate(self, ipv6_addr: str) -> Dict:
        """
        IPv6アドレスから全てのMAP-Eパラメータを計算

        Args:
            ipv6_addr: IPv6アドレスまたはプレフィックス

        Returns:
            計算結果の辞書
        """
        # IPv6アドレスを正規化
        if "/" in ipv6_addr:
            ipv6_addr = ipv6_addr.split("/")[0]

        # EA bitsを抽出
        ea_bits = self.extract_ea_bits(ipv6_addr)

        # IPv4アドレスを計算
        ipv4_addr = self.calculate_ipv4_address(ea_bits)

        # PSIDを計算
        psid = self.calculate_psid(ea_bits)

        # ポート範囲を計算
        port_range = self.calculate_port_range(psid)
        usable_ranges = self.get_usable_port_ranges(psid)

        return {
            "ipv6_address": ipv6_addr,
            "ipv4_address": ipv4_addr,
            "psid": psid,
            "port_range": port_range,
            "usable_port_ranges": usable_ranges,
            "total_ports": port_range[1] - port_range[0] + 1,
            "ea_bits": ea_bits,
            "br_address": self.rule["br"],
            "provider": self.rule["name"],
        }


def detect_provider(ipv6_addr: str) -> str:
    """
    IPv6アドレスからプロバイダを自動検出

    Args:
        ipv6_addr: IPv6アドレス

    Returns:
        プロバイダ名
    """
    addr = ipaddress.IPv6Address(ipv6_addr.split("/")[0])

    for provider, rule in MAPECalculator.PROVIDER_RULES.items():
        prefix = ipaddress.IPv6Network(f"{rule['ipv6_prefix']}/{rule['ipv6_prefix_len']}")
        if addr in prefix:
            return provider

    return None


def print_result(result: Dict):
    """計算結果を整形して表示"""
    print("\n" + "=" * 60)
    print(f"MAP-E Parameter Calculator - {result['provider']}")
    print("=" * 60)
    print(f"\n📍 Input IPv6 Address: {result['ipv6_address']}")
    print(f"🌐 Border Relay (BR):  {result['br_address']}")
    print(f"\n🔢 Calculated IPv4 Address: {result['ipv4_address']}")
    print(f"🆔 PSID (Port Set ID):      {result['psid']}")
    print(f"🔧 EA Bits (hex):           0x{result['ea_bits']:04x}")
    print("\n📊 Port Range:")
    print(f"   Total Range: {result['port_range'][0]} - {result['port_range'][1]}")
    print(f"   Total Ports: {result['total_ports']}")

    if result["usable_port_ranges"]:
        print("\n✅ Usable Port Ranges:")
        for start, end in result["usable_port_ranges"]:
            print(f"   {start} - {end} ({end - start + 1} ports)")
    else:
        print("\n❌ No usable ports (all in well-known range 0-1023)")

    print("\n" + "=" * 60)
    print("📝 NAT Configuration Example:")
    print("=" * 60)

    if result["usable_port_ranges"]:
        start, end = result["usable_port_ranges"][0]
        print("\n# nftables:")
        print(f"oifname map-e0 ip saddr 192.168.1.0/24 masquerade to :{start}-{end}")
        print("\n# iptables:")
        print(f"iptables -t nat -A POSTROUTING -o map-e0 -j MASQUERADE --to-ports {start}-{end}")

    print("\n" + "=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="MAP-E IPv4 Address and Port Calculator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s 2404:8e00:1234:5678::1
  %(prog)s 2404:8e00:1234:5678::/64
  %(prog)s 2404:8e00:1234:5678::1 --provider v6plus
  %(prog)s --list-providers

Supported Providers:
  v6plus   - v6プラス (JPNE)
  ocn      - OCNバーチャルコネクト
  transix  - transix (DS-Lite/MAP-E)
        """,
    )

    parser.add_argument(
        "ipv6_address", nargs="?", help="IPv6 address or prefix (e.g., 2404:8e00:1234:5678::1 or 2404:8e00:1234::/56)"
    )

    parser.add_argument(
        "-p",
        "--provider",
        choices=MAPECalculator.PROVIDER_RULES.keys(),
        help="Specify provider (auto-detect if not specified)",
    )

    parser.add_argument("-l", "--list-providers", action="store_true", help="List supported providers and exit")

    args = parser.parse_args()

    # プロバイダ一覧表示
    if args.list_providers:
        print("\n📋 Supported MAP-E Providers:")
        print("=" * 60)
        for key, rule in MAPECalculator.PROVIDER_RULES.items():
            print(f"\n{key}:")
            print(f"  Name:            {rule['name']}")
            print(f"  BR Address:      {rule['br']}")
            print(f"  IPv4 Prefix:     {rule['ipv4_prefix']}/{rule['ipv4_prefix_len']}")
            print(f"  IPv6 Prefix:     {rule['ipv6_prefix']}/{rule['ipv6_prefix_len']}")
            print(f"  EA bits:         {rule['ea_bits']}")
            print(f"  PSID length:     {rule['psid_len']}")
        print("\n" + "=" * 60 + "\n")
        return 0

    # IPv6アドレス必須チェック
    if not args.ipv6_address:
        parser.print_help()
        return 1

    # プロバイダの決定
    provider = args.provider
    if not provider:
        provider = detect_provider(args.ipv6_address)
        if not provider:
            print(f"❌ Error: Could not detect provider from IPv6 address: {args.ipv6_address}")
            print("   Please specify provider with --provider option")
            print("   Use --list-providers to see supported providers")
            return 1
        print(f"🔍 Auto-detected provider: {MAPECalculator.PROVIDER_RULES[provider]['name']}")

    # MAP-E計算
    try:
        calculator = MAPECalculator(MAPECalculator.PROVIDER_RULES[provider])
        result = calculator.calculate(args.ipv6_address)
        print_result(result)
        return 0
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
