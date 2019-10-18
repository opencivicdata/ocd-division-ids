import urllib.request
import csv
import json

state_codes = { "br": "S04", "dl": "U05", "jh": "S27", "hr": "S07", "mh": "S13" }
consts_file = "{}_constituencies"
districts_url = "https://electoralsearch.in/Home/GetDistList?st_code={}"
constituency_url = "https://electoralsearch.in/Home/GetAcList?dist_no={}&st_code={}"
replacements = {
    "_": " ",
    "-": ""
}
columns = ["constituency", "district"]
name_replacements = {
    "Kaimur (bhabua)".upper(): "Kaimur",
    "saraikela- kharswan".upper(): "Saraikela Kharswan"
}

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


state_consts = {}

for state, state_code in state_codes.items():
  with urllib.request.urlopen(districts_url.format(state_code)) as response:
    data = response.read()
    encoding = response.info().get_content_charset("utf-8")
    res = json.loads(data.decode(encoding))
  const_districts = {}
  for district in res:

    dist_code = district["dist_no"]
    init_name = district["dist_name"]
    if state == "dl" and "delhi" not in district["dist_name"].lower():
      init_name = init_name.replace(" ", "") + " DELHI"
    district_name = clean_name(init_name)
    with urllib.request.urlopen(constituency_url.format(dist_code, state_code)) as const_response:
      data = const_response.read()
      encoding = const_response.info().get_content_charset("utf-8")
      const_res = json.loads(data.decode(encoding))
    for const in const_res:
      const_name = clean_name(const["ac_name"])
      const_districts[const_name] = district_name
  state_consts[state] = const_districts


for state, consts in sorted(state_consts.items()):
  with open("{}_constituencies.csv".format(state), "w+") as f:
    writer = csv.DictWriter(f, fieldnames=columns)
    for const, district in consts.items():
      writer.writerow({ "constituency": const, "district": district })
