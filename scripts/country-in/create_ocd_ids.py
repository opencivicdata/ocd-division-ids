"""
Program to generate OCD IDs for the 2019 Indian Vidhan Sabha elections.
Adaptable to generate OCD-IDs for elections with districts and constituencies.
State OCD-IDs created for Bihar, Delhi, Jharkhand, Maharashstra, and Haryana.

Information on Districts and Constituencies for each state are read from a
CSV file called `{state_abbreviation}_constituencies.csv`. A left-join is executed
on the table read from this CSV and another (required) CSV called
`{state_abbrev}_districts.csv`, on the "district" column, creating a new table
that adds an abbreviation column to the original constituencies table.

The {state_abbreviation}_constituencies.csv files can be created using the
`fetch_constituencies.py` script available in this directory.

This script writes OCD-IDs into a CSV with the election name, in this case
vidhan_sabha.csv. It also prints out the parents OCD-IDs that need to be added
to the `federal_states_territories.csv` file before `compile.py` is run.

Source of truth for district and constituency names: https://electoralsearch.in
"""
from __future__ import print_function
import csv


# For file names and OCD-IDs.
state_abbrevs = {"hr": "Haryana", "mh": "Maharashtra",
                 "br": "Bihar", "dl": "Delhi", "jh": "Jharkhand"}
country = "in"

# Final output CSV name and its columns.
election_name = "Vidhan Sabha"
columns = ["id", "name"]

# Final table being written to ocd-id CSV
write_table = []
new_file = True

# If top level OCD-IDs don't exist
# Prints them to stdout to be added to
# federal_states_territories.csv.
print_top_level_ids = True

# cleans the data of certain punctuation
punc_replacements = {
    " ": "_",
    "(": "",
    ")": "",
    "-": "_"
}

def read_csv(csv_file):
  """Returns in-memory list of table rows."""
  table = []
  with open("csv/" + csv_file, "r", encoding="utf-8") as f:
      csv_reader = csv.DictReader(f)
      for row in csv_reader:
        table.append(row)
  return table

def join_table(consts, districts, state, state_abbr):
  """Joins abbrevations with constituency districts."""
  new_table = []
  ht = {} # Hashtable that stores the district abbreviation.
  for d_row in districts:
    district_key = d_row["district"]
    ht[district_key] = d_row["abbreviation"].lower()
  for c_row in consts:
    cons_district = c_row["district"].strip()

    if cons_district in ht:
      c_row["district"] = cons_district
      c_row["district_abbr"] = ht[cons_district][:2]
    else:
      raise Exception("district {} doesn't have abbrev".format(cons_district))

    constituency = c_row["constituency"]
    for old, new in punc_replacements.items():
      constituency = constituency.replace(old, new)
    c_row["constituency"] = constituency.lower()
    c_row["state"] = state
    c_row["state_abbr"] = state_abbr
    c_row["district"] = cons_district
    new_table.append(c_row)
  return new_table

def write_to_file(table):
  """Formats hardcoded OCD ID and writes to CSV file."""
  global new_file
  ocd_id = "ocd-division/country:{}/{}:{}/district:{}/cd:{}"
  rest = "{} constituency; {} district; {}"
  write_header = None

  # Used to create top level OCD IDs if they don't exist.
  parent_set = set()

  # Write headers if it's the first table being written.
  if new_file:
    open_type = "w+"
    new_file = False
    write_header = True
  else:
    open_type = "a+"
  with open("{}.csv".format(election_name.lower().replace(" ", "_")),
            open_type, encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=columns)
    if write_header:
      writer.writeheader()
      write_header = False
    for row in table:
      # An exception: Delhi is a territory, not a state.
      if row["state_abbr"] == "dl":
        state_name = "territory"
      else:
        state_name = "state"
      full_const = " ".join(word.capitalize()
                            for word in row["constituency"].split("_"))
      ocd_id_row = {
          "id": ocd_id.format(country, state_name, row["state_abbr"],
                              row["district_abbr"], row["constituency"]),
          "name": rest.format(full_const, row["district"], row["state"])
      }
      if print_top_level_ids:
        parent = ocd_id_row["id"].rsplit("/", 1)
        parent_set.add("/".join(parent[:-1]) + "," + row["district"])
      writer.writerow(ocd_id_row)
  if print_top_level_ids:
    for parent in sorted(parent_set, key=lambda x: x.split(",")[-1]):
      print(parent)

# Driver script
for state_abbr, state  in sorted(state_abbrevs.items()):
  consts = read_csv("{}_constituencies.csv".format(state_abbr))
  districts = read_csv("{}_districts.csv".format(state_abbr))
  write_table.append(join_table(consts, districts, state, state_abbr))
for t in write_table:
  write_to_file(t)
