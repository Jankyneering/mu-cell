#!/usr/bin/env python3
"""
Upload RF test results (TX Power, RX Sensitivity) and EEPROM .bin files
from a CSV to InvenTree, against serialized µCell Baseband stock items.

CSV format (UTF-8, header row required):
    "Batch Number","Serial number","TX Power (dBm)","RX Sensitivity (dBm)"

.bin file format: one file per serial, named BATCH-SERIAL.bin
(for example BATCH0001-0042.bin).

Each .bin file becomes a PASS test result on the "EEPROM" test template,
with the file attached to that test result.

Requirements:
    pip install inventree python-dotenv

secrets.env (same folder as this script) must contain:
    INVENTREE_URL=https://inventree.fredcorp.cc
    INVENTREE_API_KEY=your_token_here

Usage:
    python upload_test_results.py BATCH0001.csv            # send results AND .bin files
    python upload_test_results.py BATCH0001.csv --results  # send test results only
    python upload_test_results.py BATCH0001.csv --bin      # send .bin files only
    python upload_test_results.py BATCH0001.csv --results --bin --bin-dir ./eeprom
"""

import argparse
import csv
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from inventree.api import InvenTreeAPI

# --- Configuration ---------------------------------------------------------

PART_IPN = "mu-cell-bb"
SERIAL_COLUMN = "Serial number"
BATCH_COLUMN = "Batch Number"

# CSV column -> (InvenTree test template name, pass/fail rule)
TESTS = {
    "TX Power (dBm)": {
        "template_name": "TX Power (dBm)",
        "passes": lambda v: v > 0,
    },
    "RX Sensitivity (dBm)": {
        "template_name": "RX Sensitivity (dBm)",
        "passes": lambda v: v < -100,
    },
}

# Test template that receives the .bin file attachment
EEPROM_TEMPLATE_NAME = "EEPROM"

# --- Setup -----------------------------------------------------------------

def load_config() -> tuple[str, str]:
    env_path = Path(__file__).parent / "secrets.env"
    load_dotenv(env_path)
    key = os.getenv("INVENTREE_API_KEY")
    url = os.getenv("INVENTREE_URL")
    if not key or not url:
        sys.exit(f"INVENTREE_API_KEY and/or INVENTREE_URL missing from {env_path}")
    return url, key


def connect() -> InvenTreeAPI:
    url, key = load_config()
    return InvenTreeAPI(url, token=key)


def get_part_pk(api: InvenTreeAPI) -> int:
    parts = api.get("part/", params={"IPN": PART_IPN})
    if not parts:
        sys.exit(f"No part found with IPN '{PART_IPN}'")
    if len(parts) > 1:
        sys.exit(f"Multiple parts found with IPN '{PART_IPN}', aborting")
    return parts[0]["pk"]


def get_test_template_pks(api: InvenTreeAPI, part_pk: int, want_eeprom: bool) -> dict:
    templates = api.get("part/test-template/", params={"part": part_pk})
    by_name = {t["test_name"]: t["pk"] for t in templates}
    for cfg in TESTS.values():
        if cfg["template_name"] not in by_name:
            sys.exit(
                f"Test template '{cfg['template_name']}' not found on part "
                f"(available: {list(by_name.keys())})"
            )
    if want_eeprom and EEPROM_TEMPLATE_NAME not in by_name:
        sys.exit(
            f"Test template '{EEPROM_TEMPLATE_NAME}' not found on part "
            f"(available: {list(by_name.keys())})"
        )
    return by_name


def get_stock_item_pk(api: InvenTreeAPI, part_pk: int, batch: str, serial: str):
    items = api.get("stock/", params={"part": part_pk, "batch": batch, "serial": serial})
    if not items:
        return None
    if len(items) > 1:
        print(f"  ! multiple stock items match batch {batch} / serial {serial}, skipping")
        return None
    return items[0]["pk"]


# --- Upload helpers ----------------------------------------------------------

def upload_test_results(api: InvenTreeAPI, template_pks: dict, stock_pk: int,
                        batch: str, serial: str, row: dict) -> tuple[int, int]:
    """Upload the RF test results for one stock item. Returns (ok, failed)."""
    ok, failed = 0, 0
    for column, cfg in TESTS.items():
        raw = row[column].strip()
        try:
            value = float(raw)
        except ValueError:
            print(f"[{batch}/{serial}] bad value '{raw}' for {column}, skipping test")
            continue

        result = cfg["passes"](value)
        api.post(
            "stock/test/",
            data={
                "stock_item": stock_pk,
                "template": template_pks[cfg["template_name"]],
                "value": raw,
                "result": result,
            },
        )
        print(f"[{batch}/{serial}] {column} = {raw} -> {'PASS' if result else 'FAIL'}")
        ok += 1 if result else 0
        failed += 0 if result else 1
    return ok, failed


def upload_eeprom_bin(api: InvenTreeAPI, template_pks: dict, stock_pk: int,
                      batch: str, serial: str, bin_dir: Path) -> bool:
    """Upload one .bin file as a PASS result on the EEPROM test, with the file
    attached to that result. Returns True on success."""
    path = bin_dir / f"{batch}-{serial}.bin"
    if not path.is_file():
        print(f"[{batch}/{serial}] .bin file not found: {path}, skipping")
        return False

    with open(path, "rb") as f:
        response = api.post(
            "stock/test/",
            data={
                "stock_item": stock_pk,
                "template": template_pks[EEPROM_TEMPLATE_NAME],
                "result": True,
                "value": path.name,
            },
            files={
                "attachment": (path.name, f, "application/octet-stream"),
            },
        )

    if not response:
        print(f"[{batch}/{serial}] EEPROM upload failed for {path.name}")
        return False

    print(f"[{batch}/{serial}] EEPROM <- {path.name} ({path.stat().st_size} bytes)")
    return True


# --- Main --------------------------------------------------------------------

def main(csv_path: str, send_results: bool, send_bins: bool, bin_dir: Path):
    api = connect()
    part_pk = get_part_pk(api)
    template_pks = get_test_template_pks(api, part_pk, want_eeprom=send_bins)

    ok, failed, missing = 0, 0, 0
    bins_ok, bins_failed = 0, 0

    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            batch = row[BATCH_COLUMN].strip()
            serial = row[SERIAL_COLUMN].strip()
            stock_pk = get_stock_item_pk(api, part_pk, batch, serial)
            if stock_pk is None:
                print(f"[{batch}/{serial}] stock item not found, skipping")
                missing += 1
                continue

            if send_results:
                r_ok, r_failed = upload_test_results(
                    api, template_pks, stock_pk, batch, serial, row
                )
                ok += r_ok
                failed += r_failed

            if send_bins:
                if upload_eeprom_bin(api, template_pks, stock_pk, batch, serial, bin_dir):
                    bins_ok += 1
                else:
                    bins_failed += 1

    print()
    if send_results:
        print(f"{ok} passing results, {failed} failing results.")
    if send_bins:
        print(f"{bins_ok} .bin files uploaded, {bins_failed} .bin files failed or missing.")
    print(f"{missing} serials not found.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Upload RF test results and/or EEPROM .bin files to InvenTree."
    )
    parser.add_argument("csv_file", help="CSV file with batch/serial/test columns")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--results", action="store_true",
        help="upload RF test results only",
    )
    mode.add_argument(
        "--bin", action="store_true",
        help="upload .bin files (EEPROM test) only",
    )
    parser.add_argument(
        "--bin-dir", type=Path, default=None,
        help="folder that holds the BATCH-SERIAL.bin files (default: CSV folder)",
    )
    args = parser.parse_args()

    # No mode flag given: send both
    send_results = not args.bin
    send_bins = not args.results
    bin_dir = args.bin_dir if args.bin_dir else Path(args.csv_file).resolve().parent

    main(args.csv_file, send_results, send_bins, bin_dir)
