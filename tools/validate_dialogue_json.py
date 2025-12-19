#!/usr/bin/env python3
"""Validate dialogue JSON files against the repo schema.

Usage: tools/validate_dialogue_json.py --schema <schema.json> --dir <dialogue_dir> [--pattern "**/*.json"]
Exits non-zero on validation failures.
"""

import argparse
import glob
import json
import os
import sys
from jsonschema import Draft7Validator


def validate_file(path, schema, validator):
    with open(path, 'r', encoding='utf-8') as fh:
        try:
            data = json.load(fh)
        except Exception as e:
            return [("parse_error", str(e))]
    errors = []
    for err in validator.iter_errors(data):
        errors.append((err.path, err.message))
    return errors


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--schema', required=True)
    ap.add_argument('--dir', required=True)
    ap.add_argument('--pattern', default='**/*.json')
    args = ap.parse_args()

    if not os.path.exists(args.schema):
        print(f"Schema file not found: {args.schema}")
        sys.exit(2)
    if not os.path.exists(args.dir):
        print(f"Dialogue dir not found: {args.dir}")
        sys.exit(2)

    with open(args.schema, 'r', encoding='utf-8') as fh:
        schema = json.load(fh)

    validator = Draft7Validator(schema)

    pattern = os.path.join(args.dir, args.pattern)
    files = glob.glob(pattern, recursive=True)

    if not files:
        print("No dialogue JSON files found to validate.")
        return 0

    failed = 0
    for f in sorted(files):
        errs = validate_file(f, schema, validator)
        if errs:
            failed += 1
            print(f"\nValidation errors in: {f}")
            for p, msg in errs:
                print(f" - {p}: {msg}")

    if failed:
        print(f"\nJSON validation failed for {failed} file(s).")
        sys.exit(1)
    else:
        print("All dialogue JSON files validate against schema.")
        return 0

if __name__ == '__main__':
    sys.exit(main())
