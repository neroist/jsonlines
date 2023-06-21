# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import jsonlines

test "can parse string":
  let jsonl = parseJsonLines("""["im", "tired"]
  {"no": ["way", "fr?"]}""")

  check jsonl[0] == %* ["im", "tired"]

test "can parse file":
  let jsonl = parseJsonLinesFile("tests/data/1.jsonl")

  check jsonl[3] == %* ["May", "2012B", 14, false]

test "can throw errors":
  expect(JsonParsingError):
    discard parseJsonLines("[1, 2, 4, fdgfdgd 444ff]")
