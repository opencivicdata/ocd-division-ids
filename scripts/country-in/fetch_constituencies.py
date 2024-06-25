"""
This script fetches districts and constituencies for Indian states from
the official Indian electoral site for Vidhan Sabha elections. It then
outputs constituencies and districts for each state in a CSV file named
corresponding to each state. From these CSVs, one may run the `create_ocd_id.py`
script to generate OCD-IDs (after separately creating district abbreviation
files for each state).

The official site is https://electoralsearch.in
"""
import urllib.request
import csv
import json

# Codes gotten from official site.
state_codes = { "br": "S04", "dl": "U05", "jh": "S27", "hr": "S07", "mh": "S13" }
consts_file = "{}_constituencies"
districts_url = "https://electoralsearch.in/Home/GetDistList?st_code={}"
constituency_url = "https://electoralsearch.in/Home/GetAcList?dist_no={}&st_code={}"

# CSV columns
columns = ["constituency", "district"]

# Any specific data-cleaning replacements that should be done
# should be added here.
name_replacements = {
    "Kaimur (bhabua)".upper(): "Kaimur",
    "saraikela- kharswan".upper(): "Saraikela Kharswan"
}

replacements = {
    "_": " ",
    "-": ""
}

state_consts = {}

# Cleans up each a given column cell.
def clean_name(name):
  name = name.strip()
  name_test = name.split(" ")
  if len(name_test) > 1 and name_test[1].startswith("("):
    name = name_test[0]
  if name in name_replacements:
    return name_replacements[name]
  else:
    for old, new in replacements.items():
      name = name.replace(old, new)
    return " ".join([n.lower().capitalize() for n in name.split(" ")])

# Driver script
for state, state_code in state_codes.items():
  # Get each state's district data
  with urllib.request.urlopen(districts_url.format(state_code)) as response:
    data = response.read()
    encoding = response.info().get_content_charset("utf-8")
    res = json.loads(data.decode(encoding))
  const_districts = {}

  # From each district get information to fetch its constituencies.
  for district in res:
    dist_code = district["dist_no"]
    init_name = district["dist_name"]
    if state == "dl" and "delhi" not in district["dist_name"].lower():
      init_name = init_name.replace(" ", "") + " DELHI"
    district_name = clean_name(init_name)
    with urllib.request.urlopen(constituency_url.format(
        dist_code, state_code)) as const_response:
      data = const_response.read()
      encoding = const_response.info().get_content_charset("utf-8")
      const_res = json.loads(data.decode(encoding))

    # create dictionary of constituencies to their districts.
    for const in const_res:
      const_name = clean_name(const["ac_name"])
      const_districts[const_name] = district_name
  state_consts[state] = const_districts


# For each state's constituency, write them to a state specific CSV
for state, consts in sorted(state_consts.items()):
  with open("{}_constituencies.csv".format(state), "w+") as f:
    writer = csv.DictWriter(f, fieldnames=columns)
    for const, district in consts.items():
      writer.writerow({ "constituency": const, "district": district })
