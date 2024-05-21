"""
1. Visit https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Ridings
1. Uncheck *[Currently Active] Equals 'Active'* below the table
1. Check *Additional Information* in the *Column Chooser* menu above the table
1. Click *Export all data to Excel* in the *Export* menu above the table
1. Run this command from the same directory as the ParlinfoRidings.xlsx file
"""

import os.path
import re
import sys
from datetime import datetime, timedelta

import pandas as pd
import copy

abolished = {
    "Cariboo District",
}
renamed = {
    "Chambly": "Chambly—Verchères",
    "East Calgary": "Calgary East",
    "Essex": "Essex—Windsor",  # Essex—Windsor omits the word "ESSEX".
    "Essex—Kent": "Kent—Essex",
    "Hamilton—Wentworth": "Wentworth—Burlington",
    "St. Boniface": "Saint Boniface",
    "Saint-Léonard": "Saint-Léonard—Saint-Michel",  # Saint-Léonard 1976-1977's information is repeated in 1988-1997.
    "Terrebonne": "Terrebonne—Blainville",
}
alias_corrections = {
    "Argenteuil": "ocd-division/country:ca/province:qc/fed:argenteuil-deux-montagnes",
    "Beauharnois": "ocd-division/country:ca/province:qc/fed:beauharnois-salaberry",
    "Charlesbourg": "ocd-division/country:ca/province:qc/fed:charlesbourg-haute-saint-charles",
    "Chicoutimi": "ocd-division/country:ca/province:qc/fed:chicoutimi-le_fjord",
    "Gloucester—Carleton": "ocd-division/country:ca/province:on/fed:orléans",
    "Huron": "ocd-division/country:ca/province:on/fed:huron-bruce",
    "Longueuil": "ocd-division/country:ca/province:qc/fed:longueuil-saint-hubert",
    "Maisonneuve": "ocd-division/country:ca/province:qc/fed:maisonneuve-rosemont",
    "Missisquoi": "ocd-division/country:ca/province:qc/fed:brome-missisquoi",
    "North Okanagan—Shuswap": "ocd-division/country:ca/province:bc/fed:okanagan-shuswap",
    "Richelieu": "ocd-division/country:ca/province:qc/fed:bas-richelieu-nicolet-bécancour",
    "Rimouski": "ocd-division/country:ca/province:qc/fed:rimouski-mitis",
    "Sarnia": "ocd-division/country:ca/province:on/fed:sarnia-lambton",
    "Témiscouata": "ocd-division/country:ca/province:qc/fed:rivière-du-loup-témiscouata"
}

pd.set_option("display.max_columns", None)
pd.set_option("display.max_colwidth", None)
pd.set_option("display.max_rows", None)

### Load and clean

df = pd.read_excel("ParlinfoRidings.xlsx")

# Rename columns.
df.rename(
    columns={
        "Name": "name",
        "Start Date": "validFrom",
        "End Date": "validThrough",
    },
    errors="raise",
    inplace=True,
)

# Clean "name".
df["name"] = df["name"].str.replace("--", "—")  # double-hyphen, m-dash

# Normalize "Additional Information".
df["Additional Information"] = (
    df["Additional Information"]
    .str.lower()
    .str.translate(str.maketrans("“”—", '""-'))  # m-dash, hyphen
    .str.replace(r"\s+", " ", regex=True)
)

# Remove districts that were abolished before coming into force.
for substring in (
    "abolished before coming into force.",
    "the electoral district changed name in 2015 before coming into effect.",
):
    df = df[~df["Additional Information"].str.contains(substring)]

# Add missing dates if provided in "Additional Information". (Hardcoded, since fewer than ten.)
missing = {
    "Fort Nelson—Peace River": ("1976", "1978"),
    "Gloucester—Carleton": ("1996", "1997"),
    "Regina—Arm River": ("1996", "1997"),
    "Rimouski": ("1997", "1997"),
    "Saskatchewan": ("1905", "1907"),
    "Saskatoon—Rosetown": ("1996", "1997"),
}
condition = df["validFrom"].isna() & df["validThrough"].isna()
assert len(df[condition]) >= len(missing), f"{df[condition]}\n\nThe code contains more missing values than necessary."
for label, row in df[condition].iterrows():
    valid_from, valid_through = missing[row["name"]]
    df.at[label, "validFrom"] = valid_from
    df.at[label, "validThrough"] = valid_through

# Merge districts that appear as separate entries due to a change in the French name only.
condition = df["Additional Information"].str.contains("the electoral district's french name changed in ")
# Sort districts in reverse chronological order, so that the earliest validFrom is the last merged.
for label, row in df[condition].sort_values("validFrom", ascending=False).iterrows():
    valid_from = (datetime.strptime(row["validThrough"], "%Y-%m-%d") + timedelta(days=1)).strftime("%Y-%m-%d")
    condition = (df["name"] == row["name"]) & (df["validFrom"] == valid_from)
    assert len(df[condition]) == 1, f"Zero or multiple successors found to {row['name']} valid from {valid_from}"
    df.loc[condition, "validFrom"] = row["validFrom"]
    df.drop(label, inplace=True)

# Perform sanity checks.
assert df.shape[1] == 7, f"{df.columns}\nExpected 7 columns."
t = ~df["Currently Active"].isin(["Active", "Not Active"])
assert not t.any(), f"{df[t]}\n\nSome divisions are neither active nor inactive."
t = (df["Currently Active"] == "Active") & df["validThrough"].notna()
assert not t.any(), f"{df[t]}\n\nSome active divisions have an end date."
t = (df["Currently Active"] == "Not Active") & df["validThrough"].isna()
assert not t.any(), f"{df[t]}\n\nSome inactive divisions have no end date."

### Build ID tables

# Create initial type IDs. Years are suffixed later for collisions.
df["id"] = (
    "ocd-division/country:ca/"
    # Scope electoral districts by province or territory, to avoid collisions.
    + df["Province"].map(
        {
            "Alberta": "province",
            "British Columbia": "province",
            "Manitoba": "province",
            "New Brunswick": "province",
            "Newfoundland and Labrador": "province",
            "Nova Scotia": "province",
            "Ontario": "province",
            "Prince Edward Island": "province",
            "Quebec": "province",
            "Saskatchewan": "province",
            "Yukon": "territory",
            "Northwest Territories": "territory",
            "Nunavut": "territory",
        }
    )
    + ":"
    + df["Province"].map(
        {
            "Alberta": "ab",
            "British Columbia": "bc",
            "Manitoba": "mb",
            "New Brunswick": "nb",
            "Newfoundland and Labrador": "nl",
            "Northwest Territories": "nt",
            "Nova Scotia": "ns",
            "Nunavut": "nu",
            "Ontario": "on",
            "Prince Edward Island": "pe",
            "Quebec": "qc",
            "Saskatchewan": "sk",
            "Yukon": "yt",
        }
    )
    + "/fed:"
    # - Assiniboia West
    # - "Uppercase characters must be converted to lowercase."
    # - "Spaces must be converted to underscores."
    # - Convert m-dash to hyphen.
    # - Remove commas and parentheses.
    # - "All invalid characters must be converted to tildes (~)."
    + df["name"].str.lower().str.translate(str.maketrans(" —'’", "_-~~", ",()")).str.strip()
)
df["sameAs"] = ""

# Sort by id and validFrom, to suffix years to later districts.
df.sort_values(["id", "validFrom"], inplace=True)

# Create the initial tables.
abolished_condition = (
    df["Additional Information"].str.contains("the electoral district was abolished in ")
    | df["Additional Information"].str.contains("la circonscription électorale fut abolie en ")
    # Ridings in the Northwest Territories prior to the creation of Alberta and Saskatchewan:
    #
    # - Alberta (Provisional District)
    # - Assiniboia East
    # - Assiniboia West
    # - Calgary
    # - Edmonton
    # - Humboldt
    # - Mackenzie
    # - Qu'Appelle
    # - Saskatchewan (Provisional District)
    # - Strathcona
    | df["Additional Information"].str.contains("the electoral district of nwt created to represent entire territory.")
)
dfs = {
    # Federal electoral districts that are active.
    "current": {
        "df": df[df["Currently Active"] == "Active"],
        "columns": ["validFrom"],
    },
    # Federal electoral districts that have been abolished according to the Library of Parliament.
    "abolished": {
        "df": df[(df["Currently Active"] == "Not Active") & abolished_condition],
        "columns": ["validFrom", "validThrough"],
    },
    # Federal electoral districts that have been renamed.
    "aliases": {
        "df": df[(df["Currently Active"] == "Not Active") & ~abolished_condition],
        "columns": ["sameAs"],
    },
}

# Track IDs that have been seen. Subsequent occurrences must have a year appended.
seen = set()
# Track year-appended IDs that been taken. These must be unique.
taken = set()

# Append years to duplicate names within abolished and current districts.
for key, dups in (("abolished", True), ("current", True), ("aliases", True)):
    d = dfs[key]["df"]
    for label, row in d.iterrows():
        if row["id"] not in seen:
            # Allow duplicates between current districts (if any) to be caught by the compile step.
            if dups:
                seen.add(row["id"])
            continue

        # Append a year to a subsequent occurrence to achieve uniqueness.
        type_id = f"{row['id']}-{row['validFrom'][:4]}"
        d.at[label, "id"] = type_id

        # If more than one district has the same name and is valid from the same year, we have a problem.
        assert type_id not in taken, f"{type_id} already taken. A new naming policy is required."
        taken.add(type_id)

# In case it's relevant at a future date, renames use the wording:
#
# - the elctoral district changed name in
# - the electoral district changed name in
# - the electoral district name changed in
# - the electoral district's english name changed
# - the electoral district's name changed in
# - the electoral district's name was changed in
# - the name of the electoral district was changed in
d = dfs["aliases"]["df"]
for label, row in d.sort_values("validFrom", ascending=False).iterrows():
    if row["name"] in alias_corrections:
      d.at[label, "sameAs"] = alias_corrections[row["name"]]
      continue
    regex = r' for the (?:name|word[s:]?) "' + re.escape(row["name"]).replace("—", " ?--? ?").lower() + r'\.?"'
    matches = df[df["Additional Information"].str.contains(regex, regex=True)]
    if not matches.empty:
      # Filter out matches where validFrom is later than the validThrough of rename
      for _, match in matches.iterrows():
        if not pd.isna(match["validThrough"]):
          if (int(row["validFrom"][:4]) + 1 > int(match["validThrough"][:4])):
            continue
        pd.set_option('mode.chained_assignment',None)
        dfs["abolished"]["df"].loc[df["id"] == row["id"], "validFrom"] = match["validFrom"]
        d.at[label, "sameAs"] = match["id"]
    else:
      d.at[label, "sameAs"] = ""
    assert len(matches) <= 1, f"{matches}\n\nMultiple matches found for {row['name']}."

# Add remaining ids  to abolished ids and remove them from aliases
abolishedIds = dfs["abolished"]["df"].loc[:,"id"].values.tolist()
noSameAsIds = d[d['sameAs'] == '']
filteredNoSameAsDf = noSameAsIds.loc[~df["id"].isin(abolishedIds)]
dfs["abolished"]["df"] = pd.concat([dfs["abolished"]["df"], filteredNoSameAsDf])
dfs["aliases"]["df"] = d[d['sameAs'] != '']

d = dfs["aliases"]["df"]
for label, row in d.sort_values("validFrom", ascending=False).iterrows():
  sameAs = row["sameAs"]
  rowId = row["id"]
  idsToChange = []
  if sameAs in d["id"].values:
    print(row["name"])
    print(d.loc[d["id"] == row["sameAs"]]["sameAs"].values[0])
    print("\n")
    idsToChange.append(rowId)
    rowId = sameAs
    sameAs = d.loc[d["id"] == sameAs]["sameAs"].values[0]
  for ocdId in idsToChange:
    dfs["aliases"]["df"].at[label, "sameAs"] = sameAs

assert (d["sameAs"] != "").all(), f"{len(d[d['sameAs'] == ''])} aliases do not have a sameAs value."

basedir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
outdir = os.path.join(basedir, "identifiers", "country-ca")
for suffix, props in dfs.items():
    outfile = os.path.join(outdir, f"ca_federal_electoral_districts-{suffix}.csv")
    props["df"][["id", "name"] + props["columns"]].to_csv(outfile, index=False)
