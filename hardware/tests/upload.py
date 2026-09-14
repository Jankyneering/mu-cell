#!/usr/bin/env python3
"""
Upload RF test results (TX Power, RX Sensitivity) from a CSV to InvenTree
as test results against serialized µCell Baseband stock items.

CSV format (UTF-8, header row required):
    "Batch Number","Serial number","TX Power (dBm)","RX Sensitivity (dBm)"

Requirements:
    pip install inventree python-dotenv

secrets.env (same folder as this script) must contain:
    INVENTREE_URL=https://inventree.fredcorp.cc
    INVENTREE_API_KEY=your_token_here

Usage:
    python upload_test_results.py BATCH0001.csv
"""

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

# --- Setup -------------------------------------------------------------

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


def get_test_template_pks(api: InvenTreeAPI, part_pk: int) -> dict:
    templates = api.get("part/test-template/", params={"part": part_pk})
    by_name = {t["test_name"]: t["pk"] for t in templates}
    for cfg in TESTS.values():
        if cfg["template_name"] not in by_name:
            sys.exit(
                f"Test template '{cfg['template_name']}' not found on part "
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


# --- Main ----------------------------------------------------------------

def main(csv_path: str):
    api = connect()
    part_pk = get_part_pk(api)
    template_pks = get_test_template_pks(api, part_pk)

    ok, failed, missing = 0, 0, 0

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

    print(f"\nDone. {ok} passing results, {failed} failing results, {missing} serials not found.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python upload_test_results.py BATCHXXXX.csv")
    main(sys.argv[1])
