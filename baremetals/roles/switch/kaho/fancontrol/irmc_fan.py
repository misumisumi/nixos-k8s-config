#!/usr/bin/env python3
import argparse
import subprocess
import sys
import time


IANA_FUJITSU = [0x80, 0x28, 0x00]
OEM_NETFN = "0x2e"
OEM_CMD = "0xf5"


def hx(value: int) -> str:
    return f"0x{value & 0xff:02x}"


def ipmitool_base(args: argparse.Namespace) -> list[str]:
    return [args.ipmitool, "-I", args.interface]


def run_raw(args: argparse.Namespace, data: list[int]) -> None:
    cmd = ipmitool_base(args) + ["raw", OEM_NETFN, OEM_CMD] + [hx(x) for x in data]
    if args.dry_run:
        print(" ".join(cmd))
        return
    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.returncode != 0:
        if proc.stdout:
            print(proc.stdout, end="")
        if proc.stderr:
            print(proc.stderr, end="", file=sys.stderr)
        raise SystemExit(proc.returncode)
    if proc.stdout.strip():
        print(proc.stdout, end="" if proc.stdout.endswith("\n") else "\n")


def raw_set_all(args: argparse.Namespace, percent: int) -> None:
    payload = IANA_FUJITSU + [0x2d, ord("F"), ord("W"), 0x01, 0xff, 0x80, percent]
    run_raw(args, payload)


def raw_clear_all(args: argparse.Namespace) -> None:
    payload = IANA_FUJITSU + [0x2d, ord("F"), ord("W"), 0x01, 0xff, 0x00, 0x00]
    run_raw(args, payload)


def raw_read(args: argparse.Namespace, indices: list[int]) -> None:
    if not 1 <= len(indices) <= 31:
        raise SystemExit("read index count must be 1..31")
    payload = IANA_FUJITSU + [0x2d, ord("F"), ord("R"), 0x01, len(indices)]
    for idx in indices:
        if not 0 <= idx <= 31:
            raise SystemExit(f"PWM index out of range 0..31: {idx}")
        payload += [idx, 0x00]
    run_raw(args, payload)


def show_fans(args: argparse.Namespace) -> None:
    cmd = ipmitool_base(args) + ["sdr", "type", "fan"]
    if args.dry_run:
        print(" ".join(cmd))
        return
    subprocess.run(cmd, check=False)


def cmd_set(args: argparse.Namespace) -> None:
    if not 0 <= args.percent <= 100:
        raise SystemExit("percent must be 0..100")
    if args.percent < 30 and not args.allow_low:
        raise SystemExit("refusing to set below 30%; pass --allow-low if you really want that")
    raw_set_all(args, args.percent)
    show_fans(args)


def cmd_clear(args: argparse.Namespace) -> None:
    raw_clear_all(args)
    show_fans(args)


def cmd_read(args: argparse.Namespace) -> None:
    raw_read(args, args.indices)


def cmd_sdr(args: argparse.Namespace) -> None:
    show_fans(args)


def cmd_watch(args: argparse.Namespace) -> None:
    while True:
        print(time.strftime("%Y-%m-%d %H:%M:%S"))
        show_fans(args)
        time.sleep(args.interval)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Control Fujitsu PRIMERGY iRMC fan PWM via local ipmitool."
    )
    parser.add_argument("--ipmitool", default="ipmitool")
    parser.add_argument("-I", "--interface", default="open")
    parser.add_argument("--dry-run", action="store_true")

    sub = parser.add_subparsers(dest="command", required=True)

    p_set = sub.add_parser("set", help="force all PWM channels to a percent")
    p_set.add_argument("percent", type=int, help="PWM duty percent, for example 40")
    p_set.add_argument("--allow-low", action="store_true", help="allow values below 30 percent")
    p_set.set_defaults(func=cmd_set)

    p_clear = sub.add_parser("clear", help="clear all PWM force and return to automatic control")
    p_clear.set_defaults(func=cmd_clear)

    p_read = sub.add_parser("read", help="read selected PWM force slots")
    p_read.add_argument(
        "indices",
        nargs="*",
        type=lambda s: int(s, 0),
        default=[0x00, 0x01, 0x19, 0x1a],
        help="PWM indices, default: 0 1 0x19 0x1a",
    )
    p_read.set_defaults(func=cmd_read)

    p_sdr = sub.add_parser("sdr", help="show fan SDR readings")
    p_sdr.set_defaults(func=cmd_sdr)

    p_watch = sub.add_parser("watch", help="repeat fan SDR readings")
    p_watch.add_argument("-n", "--interval", type=float, default=5.0)
    p_watch.set_defaults(func=cmd_watch)

    return parser


def main() -> None:
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
