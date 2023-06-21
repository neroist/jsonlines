#import std/strutils
#import std/sequtils
import std/os

import jsonlines
import nimoji
import nimib

when defined(readme):
  nbInitMd
else:
  nbInit

nb.title = "Jsonlines Documentation"
nb.darkMode()

# TODO: make TOC, see https://github.com/neroist/webui-docs

nbText: """
# jsonlines

A simple [JSON Lines](https://jsonlines.org) (and NDJSON) parser library in Nim.

> See Also: <https://neroist.github.io/jsonlines/jsonlines.html>

---

JSON Lines is a file format similar to JSON, except it can hold multiple
JSON documents in a single file, which are delimited by newlines. It's a
convenient format for storing structured data that may be processed one
record at a time and works well with unix-style text processing tools and
shell pipelines. It's also a great format for log files, and a flexible
format for passing messages between cooperating processes.

This format has three main requirements:

1. **UTF-8 Encoding.** (although this library doesn't check for that)

2. **Each line is a valid JSON value.** The most common values will be objects
   or arrays, although any JSON value is permitted. However, with this
   library, you can also choose whether or not to ignore empty lines.

3. **Line Separator is `'\n'`.** `'\r\n'` is also supported because surrounding
   white space is implicitly ignored when parsing JSON values.

Examples:

```json
{"name": "Gilbert", "wins": [["straight", "7♣"], ["one pair", "10♥"]]}
{"name": "Alexa", "wins": [["two pair", "4♠"], ["two pair", "9♠"]]}
{"name": "May", "wins": []}
{"name": "Deloise", "wins": [["three of a kind", "5♣"]]}
```

```json
{"some": "thing"}
{"foo": 17, "bar": false, "quux": true}
{"may": {"include": "nested", "objects": ["and", "arrays"]}}
```
"""

nbText: """
## Parsing JSON Lines

To parse JSON Lines data, all you simply have to do is use the
[parseJsonLines](https://neroist.github.io/jsonlines/jsonlines.html#parseJsonLines%2Cstring%2Cbool)
proc.
"""

nbCode:
  let jsonl = parseJsonLines("""{"some": "thing"}
{"foo": 17, "bar": false, "quux": true}
{"may": {"include": "nested", "objects": ["and", "arrays"]}}
""")

  echo jsonl

nbText: """
This parses the data into a simple JsonLines object, which has a nodes
attribute, containing a seq of all the
[JsonNodes](https://nim-lang.org/docs/json.html#JsonNode) in the document.

This proc also works with Streams!
"""

nbText: emojize"""
### Parsing from a file

> **:warning: Note:** This functionality is not supported on the JS backend

To parse from a file, you can:

1. Read the file and use [parseJsonLines](https://neroist.github.io/jsonlines/jsonlines.html#parseJsonLines%2Cstring%2Cbool)

2. Create the file stream yourself and use [parseJsonLines](https://neroist.github.io/jsonlines/jsonlines.html#parseJsonLines%2CStream%2Cstring%2Cbool)

3. Simply call [parseJsonLinesFile](https://neroist.github.io/jsonlines/jsonlines.html#parseJsonLinesFile%2Cstring) with the name/location of the file.

Example for #3:

**Example file `1.jsonl`**:

```json
["Name", "Session", "Score", "Completed"]
["Gilbert", "2013", 24, true]
["Alexa", "2013", 29, true]
["May", "2012B", 14, false]
["Deloise", "2012A", 19, true]
```

**Nim code**:
"""

setCurrentDir("../docsrc")

nbCode:
  echo parseJsonLinesFile("1.jsonl")

nbText: """
## Retrieving JSON Data

Since JSON Lines is simply just a list of JSON values seperated by newlines,
it can be simply represented as a list of JsonNodes. the
[`[]`](https://neroist.github.io/jsonlines/jsonlines.html#[]%2CJsonLines%2C)
operator can be used to get the JsonNode at index `idx`, and the
[`[]=`](https://neroist.github.io/jsonlines/jsonlines.html#[]%3D%2CJsonLines%2Cint%2C)
operator can be used to set a JsonNode.

Example:
"""

nbCode:
  const data = """
{"creator": {"handle": "Wendigoon", "display_name": "Wendigoon"}, "video": {"id": "gCUFztOkrEU", "views": 2088488, "title": "Dante's Purgatorio & The 9 Levels of Purgatory Explained"}}
{"creator": {"handle": "TomScottGo", "display_name": "Tom Scott"}, "video": {"id": "BxV14h0kFs0", "views": 65367317, "title": "This Video Has 65,367,317 Views"}}
{"creator": {"handle": "HBMmaster", "display_name": "jan Misali"}, "video": {"id": "qID2B4MK7Y0", "views": 1272282, "title": "a better way to count"}}
{"creator": {"handle": "HBMmaster", "display_name": "jan Misali"}, "video": {"id": "2EZihKCB9iw", "views": 272019, "title": "what is toki pona? (toki pona lesson one)"}}
{"creator": {"handle": "SarahZ", "display_name": "Sarah Z"}, "video": {"id": "ohFyOjfcLWQ", "views": 3115062, "title": "A Brief History of Homestuck"}}
"""

  let jsonl2 = parseJsonLines(data)

  echo jsonl2[3].pretty # retrieve value, but make it pretty

  # std/json is exported by jsonlines, so we can use
  jsonl2[3] = %* {
    "creator": {
      "handle": "sisterhoodofsalvationllc",
      "display_name": "Sisterhood of Salvation, LLC"
    },

    "video": {
      "id": "cX4SNX_UaZI",
      "views": 393,
      "title": "Awakened Waters (in partnership with SOS LLC)"
    }
  } # set value

  echo "" # print newline to seperate values
  
  echo jsonl2[3].pretty # echo new value, but make it pretty

nbText: """
## Iterating Through JSON Lines Data

You can iterate through JSON Lines data via the standard `items` iterator,
using a JsonLines object. However you can also iterate through JSON Lines
data using the
[`jsonLines`](https://neroist.github.io/jsonlines/jsonlines.html#jsonLines.i%2Cstring%2Cbool)
iterator, which accepts a string `buffer` and supports the same parameters as
`parseJsonLines()`. It parses the string buffer line-by-line and yields the
resulting JsonNode.

Using standard `items` iterator:
"""

nbCode:
  let jsonl3 = parseJsonLines("""
["string", "length"]
["A", 5.8]
["B", 12.2]
["C", 0.34]
""")

  for node in jsonl3:
    echo node

nbText: """
Using the `jsonLines` iterator:
"""

nbCode:
  let jsonl4 = """
{"scp": {"item_number": "000", "name": "", "object_class": "#NULL"}}
{"scp": {"item_number": "002", "name": "The \"Living\" Room", "object_class": "Euclid"}}
{"scp": {"item_number": "093", "name": "Red Sea Object", "object_class": "Euclid"}}
{"scp": {"item_number": "102", "name": "Property of Marshall, Carter, and Dark Ltd.", "object_class": "Euclid"}}
{"scp": {"item_number": "999", "name": "The Tickle Monster", "object_class": "Safe"}}
{"scp": {"item_number": "2030", "name": "LA U GH IS F UN", "object_class": "Keter"}}
{"scp": {"item_number": "4000", "name": "Taboo", "object_class": "Keter"}}
"""

  for node in jsonLines(jsonl4):
    echo node["scp"]

nbText: """
## Pretty-Printing JSON Lines

You can use the [`pretty()`](https://neroist.github.io/jsonlines/jsonlines.html#pretty%2CJsonLines%2Cint) 
proc to pretty-print JSON Lines data. However, this results in invalid JSON
Lines, as each line is supposed to be a self-contained JSON value. However,
pretty printing it makes it easier for humans to view.
"""

nbCode:
  # from one of the previous sections
  echo jsonl.pretty()

nbText: """
You can also control the indent of the JSON via the `indent` parameter.
"""

# Conversion and Creation of JsonLine objects/JSON Lines Data

nbText: """
## other stuff (i guess)

ill fix this ...eventually.

Anyways, heres some of the other stuff in this library:

- `add()`: Add JsonNode to JsonLines object

- `toJArray()`: Convert JsonLines into JSON array (JArray)

- `toJsonLines()`: Convert openArray of JsonNodes to JsonLines
"""

when defined(readme):
  nb.filename = "../README.md"

setCurrentDir("../docs")

nbSave
