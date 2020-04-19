#!/usr/bin/env python3
import argparse
import os
import sys
import json

def read_dynamic_json():
    parser = argparse.ArgumentParser(
        description="Read dynamic json format file and print it to stdout")
    parser.add_argument('-f', '--json-file',
                        default=os.path.join(os.path.dirname(__file__), "inventory.json"),
                        help="Dynamic json file path")
    parser.add_argument('-l', '--list', action='store_true',
                        help='print json content to stdout')
    parser.add_argument('--host', help='print single host variables')
    args = parser.parse_args()
    try:
        with open(args.json_file) as json_file:
            json_data = json.load(json_file)
    except Exception as e:
        print("Error decoding json-file '%s': %s", args.json_file, e)
        sys.exit(1)

    if args.list:
        print(json.dumps(json_data, indent=2))
        sys.exit(0)

    if args.host:
        print(json.dumps(json_data.get("_meta", {}).get(
            "hostvars", {}).get(args.host, {}), indent=2))
        sys.exit(0)

    print("No list or host argument. ERROR")
    sys.exit(1)

if __name__ == '__main__':
    read_dynamic_json()
