from functions import make_csv_for_area_type
from data import area_types

for area_type in area_types:
    make_csv_for_area_type(**area_type)
