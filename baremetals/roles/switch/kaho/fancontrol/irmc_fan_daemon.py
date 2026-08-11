#!/usr/bin/env python3
import argparse
import json
import re
import signal
import subprocess
import sys
import time
from dataclasses import dataclass


IANA_FUJITSU = [0x80, 0x28, 0x00]
OEM_NETFN = "0x2e"
OEM_CMD = "0xf5"

TEMP_RE = re.compile(r"^([^:]+):\s+\+?(-?\d+(?:\.\d+)?)\s*°C")

STOP = False


def hx(value: int) -> str:
    return f"0x{value & 0xff:02x}"


def on_signal(signum, frame) -> None:
    global STOP
    STOP = True


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, text=True, capture_output=True)


def set_pwm(cfg: dict, percent: int) -> None:
    percent = max(cfg.get("min_pwm", 0), min(cfg.get("max_pwm", 100), percent))
    payload = IANA_FUJITSU + [0x2d, ord("F"), ord("W"), 0x01, 0xff, 0x80, percent]
    cmd = (
        [cfg["ipmitool"], "-I", cfg.get("interface", "open"), "raw", OEM_NETFN, OEM_CMD]
        + [hx(x) for x in payload]
    )
    proc = run(cmd)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout).strip() or f"ipmitool failed: {proc.returncode}")


def clear_pwm(cfg: dict) -> None:
    payload = IANA_FUJITSU + [0x2d, ord("F"), ord("W"), 0x01, 0xff, 0x00, 0x00]
    cmd = (
        [cfg["ipmitool"], "-I", cfg.get("interface", "open"), "raw", OEM_NETFN, OEM_CMD]
        + [hx(x) for x in payload]
    )
    proc = run(cmd)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout).strip() or f"ipmitool clear failed: {proc.returncode}")


def read_sensors(cfg: dict) -> dict[str, float]:
    proc = run([cfg["sensors_bin"]])
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout).strip() or f"sensors failed: {proc.returncode}")

    temps: dict[str, float] = {}
    chip = ""
    for raw_line in proc.stdout.splitlines():
        line = raw_line.rstrip()
        if not line:
            chip = ""
            continue
        if not raw_line.startswith((" ", "\t")) and not line.startswith("Adapter:") and ":" not in line:
            chip = line
            continue
        if not chip:
            continue
        match = TEMP_RE.match(line.strip())
        if match:
            label, value = match.group(1), float(match.group(2))
            temps[f"{chip}:{label}"] = value
    return temps


def ramp(temp: float | None, points: list[list[float]]) -> int:
    if temp is None:
        return 0
    if temp <= points[0][0]:
        return round(points[0][1])
    for (t0, p0), (t1, p1) in zip(points, points[1:]):
        if temp <= t1:
            ratio = (temp - t0) / (t1 - t0)
            return round(p0 + ratio * (p1 - p0))
    return round(points[-1][1])


def choose_pwm(cfg: dict, readings: dict[str, float]) -> tuple[int, dict[str, float | None]]:
    values: dict[str, float | None] = {}
    targets: list[int] = []
    for sensor in cfg["sensors"]:
        temp = readings.get(f"{sensor['chip']}:{sensor['label']}")
        values[f"{sensor['chip']}:{sensor['label']}"] = temp
        targets.append(ramp(temp, sensor["ramp"]))

    wanted = max(cfg.get("min_pwm", 0), max(targets)) if targets else cfg.get("min_pwm", 0)
    if any(v is None for v in values.values()):
        wanted = max(wanted, cfg.get("missing_sensor_pwm", 50))
    return min(cfg.get("max_pwm", 100), wanted), values


def smooth_pwm(cfg: dict, current: int | None, wanted: int) -> int:
    if current is None:
        return wanted
    if wanted > current:
        return min(wanted, current + cfg.get("step_up", 20))
    if wanted < current - cfg.get("down_hysteresis", 5):
        return max(wanted, current - cfg.get("step_down", 5))
    return current


def fmt_temp(value: float | None) -> str:
    return "NA" if value is None else f"{value:.1f}C"


def daemon(cfg: dict) -> None:
    signal.signal(signal.SIGINT, on_signal)
    signal.signal(signal.SIGTERM, on_signal)

    interval = cfg.get("interval", 10)
    min_apply_interval = cfg.get("min_apply_interval", 20)
    fail_pwm = cfg.get("fail_pwm", 0)
    clear_on_exit = cfg.get("clear_on_exit", False)

    current: int | None = None
    last_apply = 0.0

    try:
        while not STOP:
            try:
                readings = read_sensors(cfg)
                wanted, values = choose_pwm(cfg, readings)
                next_pwm = smooth_pwm(cfg, current, wanted)

                now = time.monotonic()
                if current != next_pwm and now - last_apply >= min_apply_interval:
                    set_pwm(cfg, next_pwm)
                    current = next_pwm
                    last_apply = now

                sensors_log = " ".join(f"{k}={fmt_temp(v)}" for k, v in values.items())
                print(
                    time.strftime("%Y-%m-%d %H:%M:%S"),
                    f"pwm={current if current is not None else next_pwm}%",
                    f"want={wanted}%",
                    sensors_log,
                    flush=True,
                )
            except Exception as exc:
                print(time.strftime("%Y-%m-%d %H:%M:%S"), f"error: {exc}", file=sys.stderr, flush=True)
                if fail_pwm > 0:
                    try:
                        set_pwm(cfg, fail_pwm)
                        current = fail_pwm
                    except Exception as inner:
                        print(f"failed to apply fail pwm: {inner}", file=sys.stderr, flush=True)
            time.sleep(interval)
    finally:
        if clear_on_exit:
            clear_pwm(cfg)


def load_config(path: str) -> dict:
    with open(path) as f:
        cfg = json.load(f)
    if not isinstance(cfg.get("daemon"), dict):
        raise SystemExit("config: missing 'daemon' object")
    if not isinstance(cfg.get("sensors"), list):
        raise SystemExit("config: missing 'sensors' list")
    daemon_cfg = dict(cfg["daemon"])
    daemon_cfg.setdefault("ipmitool", "ipmitool")
    daemon_cfg.setdefault("sensors_bin", "sensors")
    daemon_cfg["sensors"] = cfg["sensors"]
    return daemon_cfg


def main() -> None:
    parser = argparse.ArgumentParser(description="Fujitsu iRMC smart fan daemon (JSON config).")
    parser.add_argument("--config", required=True, help="path to JSON config file")
    args = parser.parse_args()
    daemon(load_config(args.config))


if __name__ == "__main__":
    main()
