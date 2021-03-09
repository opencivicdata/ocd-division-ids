#!/usr/bin/env python3

# Run this test from the root of the repository, as:
# $ bazel test :all --test_output=errors

import difflib
import os
import re
import subprocess
import unittest


def sort_csv_lines(csv_text):
  """Sorts the rows of a csv text, except for the header row.

  This is for ordering-independent comparison.
  """
  lines = csv_text.splitlines()
  lines[1:] = sorted(lines[1:])
  return lines


class TestSourcesMatchCommittedCSV(unittest.TestCase):
  """Check that what's committed matches the output of the compiler.

  Any change to this repository that modifies sources for some country's data
  (the stuff in identifiers/*/*.csv) should also modify the corresponding
  compiled output (identifiers/country-??.csv), such that they match.

  This test runs the compiler, and compares its output to what's been
  committed, ensuring they are equal. If this test fails, you need to re-run
  the compiler for your country, and commit the result.
  """

  def get_committed_and_compiled_data(self, country_code):
    # Read what's in the repo.
    committed_csv_path = F'identifiers/country-{country_code}.csv'
    try:
      with open(committed_csv_path, 'r', encoding='UTF-8') as committed_file:
        committed_csv = committed_file.read()
    except FileNotFoundError:
      # In the case that the commited csv file does not exist, we treat it as an
      # empty string.
      committed_csv = ''

    # Run the compiler with temp output.
    compiler_output_path = os.path.join(os.getenv('TEST_TMPDIR'), F"out-{country_code}.csv")
    subprocess.run([
        './scripts/compile.py', F'--output_csv={compiler_output_path}', country_code
    ], check=True)

    # Read the output of the compiler.
    with open(compiler_output_path, 'r', encoding='UTF-8') as compiler_output_file:
      compiler_output = compiler_output_file.read()

    return committed_csv, compiler_output

  def test_all_countries(self):
    _, csv_source_dirs, _ = list(os.walk('identifiers'))[0]
    mismatches = []
    for dirname in csv_source_dirs:
      # Ignore any files that don't match the expected pattern.
      m = re.match(r'country-(..)', dirname)
      if m:
        country_code = m.group(1)
        committed_csv, compiler_output = self.get_committed_and_compiled_data(
            country_code)
        if sort_csv_lines(committed_csv) != sort_csv_lines(compiler_output):
          mismatches.append(country_code)
    # Rather than assert as we go, which would bail out on the first failure, we
    # compile a list of all the mismatching countries, and print a message that
    # summarizes what to do.
    error_msg = ('The following countries must be recompiled to match their '
                 'source files:\n  ' + '\n  '.join(mismatches) +
                 '\n\nPlease run the following commands to rebuild:\n  ' +
                 '\n  '.join([f'./scripts/compile.py {cc}' for cc in mismatches]))
    self.assertEqual(mismatches, [], error_msg)


if __name__ == '__main__':
  unittest.main()
