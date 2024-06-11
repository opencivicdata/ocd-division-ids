#!/usr/bin/env python3
import sys
from functions import make_csv_for_area_type
from data import area_types


if sys.version_info < (3, 0):
    sys.stdout.write("Python 2.x not supported.\n")
    sys.exit(1)

for area_type in area_types:
    make_csv_for_area_type(**area_type)
