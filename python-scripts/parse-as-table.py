#!/usr/bin/env python

import re
import sys

pattern = sys.argv[1]

input = sys.stdin.read()

matches = re.finditer(
    pattern,
    input,
    re.MULTILINE)

for match in matches:
    print("\t".join(match.groups()))
