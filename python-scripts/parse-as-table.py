#!/usr/bin/env python

import re
import sys

pattern = sys.argv[1]

multiline_string = sys.stdin.read()

matches = re.finditer(
    pattern,
    multiline_string,
    re.MULTILINE)

for match in matches:
    print("\t".join(match.groups()))
