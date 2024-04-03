#!/usr/bin/env python3

import json

from glob import glob
from sys import argv
from os.path import dirname
from typing import Any, Dict

def load_dict(path) -> Dict[str, Any]:
    with open(path) as file:
        json_str = file.read()
        return json.loads(json_str)

manifest_path = glob("**/manifest.json")[0]

manifest = load_dict(manifest_path)

package_path = argv[1]

package = load_dict(package_path)
package_dir = dirname(package_path)

dependencies_old:Dict[str, str] = manifest["dependencies"]
dependencies_new:Dict[str, str] = {}

dependencies_new[package["name"]] = f"file:{package_dir}"

for package, version in dependencies_old.items():
    dependencies_new[package] = version

manifest["dependencies"] = dependencies_new

with open(manifest_path, "w+") as manifest_file:
    manifest_json = json.dumps(manifest, indent=2)
    print(manifest_json)
    manifest_file.write(manifest_json)
