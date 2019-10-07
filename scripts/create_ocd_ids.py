from __future__ import print_function
import csv
"""
Program to generate OCD IDs for the 2019 Indian Vidhan Sabha elections.
"""

contests = {"hr": "Haryana", "mh": "Maharashtra"}
columns = ["id", "name"]
country = "in"
election = "Vidhan Sabha"
write_table = []
new_file = True

# replace for other countries
district_replacements = {
    "district": " ",
    "Yamuna Nagar": "Yamunanagar",
    "Gondia": "Gondiya",
    "Gurugram": "Gurgaon",
    "Goregaon": "Gurgaon",
    "Mewat": "Nuh"
}

const_replacements = {
    " ": "_",
    "(": "",
    ")": "",
    "-": "_"
}

def read_csv(csv_file):
  # returns in-memory list of table rows
  table = []
  with open(csv_file, "rb") as f:
      csv_reader = csv.DictReader(f)
      for row in csv_reader:
        table.append(row)
  return table


def join_table(consts, districts, state, state_abbr):
  # return joined table
  new_table = []
  ht = {}
  for d_row in districts:
    if d_row["district"] in district_replacements:
      district_key = district_replacements[d_row["district"]]
    else:
      district_key = d_row["district"]
    ht[district_key] = d_row["abbreviation"].lower()

  for c_row in consts:
    # source of truth on district names:
    # https://affidavit.eci.gov.in/
    cons_district = c_row["district"]
    for old, new in district_replacements.items():
      if old in cons_district:
        cons_district = cons_district.replace(old, new)
    cons_district = cons_district.strip()

    if cons_district in ht:
      c_row["district"] = cons_district
      c_row["district_abbr"] = ht[cons_district][:2]
    else:
      c_row["district_abbr"] = None
      c_row["district"] = None

    constituency = c_row["constituency"]
    if c_row["constituency"] in district_replacements:
      constituency = cons_district
    for old, new in const_replacements.items():
      constituency = constituency.replace(old, new)
    c_row["constituency"] = constituency.lower()
    c_row["state"] = state
    c_row["state_abbr"] = state_abbr
    c_row["district"] = cons_district
    new_table.append(c_row)
  return new_table

def write_to_file(table):
  # format hardcoded OCD ID
  global new_file
  ocd_id = "ocd-division/country:{}/state:{}/district:{}/cd:{}"
  rest = "state {} district {} {} constituency {}"
  write_header = None
  # used to create top level OCD IDs if they don't exist
  # parent_set = set()
  if new_file:
    open_type = "w+"
    new_file = False
    write_header = True
  else:
    open_type = "a+"
  with open("{}.csv".format(election.lower().replace(" ", "_")), open_type) as f:
    writer = csv.DictWriter(f, fieldnames=columns)
    if write_header:
      writer.writeheader()
      write_header = False
    for row in table:
      full_const = " ".join(word.capitalize() for word in row["constituency"].split("_"))
      ocd_id_row = {
          "id": ocd_id.format(country, row["state_abbr"], row["district_abbr"], row["constituency"]),
          "name": rest.format(row["state"], row["district"], election, full_const)
      }
      # parent = ocd_id_row["id"].rsplit("/", 1)
      # parent_set.add("/".join(parent[:-1]) + "," + row["district"])
      writer.writerow(ocd_id_row)

for state_abbr, state  in contests.items():
  consts = read_csv("{}_constituencies.csv".format(state_abbr))
  districts = read_csv("{}_districts.csv".format(state_abbr))
  write_table.append(join_table(consts, districts, state, state_abbr))
for t in write_table:
  write_to_file(t)
