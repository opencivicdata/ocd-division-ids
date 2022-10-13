"""
This script renames a district csv file to <filename>-numeric_id.csv and writes the district name based
ocd ids to the <filename>.csv file. The script also adds numeric_based_id to district_name_based_id to
aliases.csv
"""

import argparse
import csv
import os


def createDistrictId(id, name):
  idSegments = id.split(':')
  # remove special characters from name
  districtName = name.lower().replace(' ', '_').replace('—', '-').replace("'", "").replace('_-_', '-')
  idSegments[-1] = districtName
  return ":".join(idSegments)

def convertIds(fileName):
  outputFileName = fileName.split(".")[0] + "-name_based_id.csv"
  outputFile = open(outputFileName, mode='w', newline='')
  aliasesFile = open("aliases.csv", mode='a', newline='')
  outputWriter = csv.writer(outputFile, delimiter=',')
  aliasesWriter = csv.writer(aliasesFile, delimiter=',')
  with open(fileName) as csvFile:
    csvReader = csv.reader(csvFile, delimiter=',')
    rowNumber = 0
    for row in csvReader:
        if rowNumber == 0:
            idIndex = row.index('id')
            nameIndex = row.index('name')
            outputWriter.writerow(row)
            rowNumber += 1
        else:
          numericId = row[idIndex]
          row[idIndex] = createDistrictId(numericId, row[nameIndex])
          outputWriter.writerow(row)
          aliasesWriter.writerow([numericId, row[idIndex], row[nameIndex] + " -- numeric ocd ids replaced with district name based ocd ids"])
          rowNumber += 1

  outputFile.close()
  aliasesFile.close()

def main():
  parser = argparse.ArgumentParser(description='combine component CSV files into one')
  parser.add_argument('fileName', type=str, default=None, help='name of file to convert')
  args = parser.parse_args()
  convertIds(args.fileName)

if __name__ == '__main__':
  main()
