# jsonlines

A Simple [JSON Lines](https://jsonlines.org) (and NDJSON) parser library in Nim.

---

JSON Lines is a file format similar to JSON, except it can hold multiple JSON
documents in a single file, which are delimited by newlines. It's a convenient format
for storing structured data that may be processed one record at a time and works well
with unix-style text processing tools and shell pipelines. It's also a great format
for log files, and a flexible format for passing messages between cooperating
processes.

This format has three main requirements:

1. UTF-8 Encoding. (although this library doesn't check for that)

2. Each line is a valid JSON value. The most common values will be objects or arrays,
although any JSON value is permitted. However, with this library, you can also choose
whether or not to ignore empty lines.

3. Line Separator is `'\n'`. `'\r\n'` is also supported because surrounding white
space is implicitly ignored when parsing JSON values.

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

## Parsing JSON Lines

To parse JSON Lines data, all you simply have to do is use the
[parseJsonLines](https://neroist.github.io/jsonlines/jsonlines.html#parseJsonLines%2Cstring%2Cbool) proc.

```nim
import jsonlines

let jsonl = parseJsonLines("""{"some": "thing"}
{"foo": 17, "bar": false, "quux": true}
{"may": {"include": "nested", "objects": ["and", "arrays"]}}
""")

echo jsonl
```

This parses the data into a simple JsonLines object, which has a nodes attribute,
containing a seq of all the [JsonNodes](https://nim-lang.org/docs/json.html#JsonNode)
in the document.

This proc also works with Streams!

### Parsing from a file

> **Note:** This functionality is not supported on the JS backend

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

```nim
import jsonlins

echo parseJsonLinesFile("./1.jsonl")
```

## Retrieving JSON Data

Since JSON Lines is simply just a list of JSON values seperated by newlines,
it can be simply represented as a list of JsonNodes. the
[`[]`](https://neroist.github.io/jsonlines/jsonlines.html#[]%2CJsonLines%2C)
operator can be used to get the JsonNode at index `idx`, and the
[`[]=`](https://neroist.github.io/jsonlines/jsonlines.html#[]%3D%2CJsonLines%2Cint%2C)
operator can be used to set a JsonNode.

Example:

```nim
import jsonlines

const data = """
{"creator": {"handle": "Wendigoon", "display_name": "Wendigoon"}, "video": {"id": "gCUFztOkrEU", "views": 2088488, "title": "Dante's Purgatorio & The 9 Levels of Purgatory Explained"}}
{"creator": {"handle": "TomScottGo", "display_name": "Tom Scott"}, "video": {"id": "BxV14h0kFs0", "views": 65367317, "title": "This Video Has 65,367,317 Views"}}
{"creator": {"handle": "HBMmaster", "display_name": "jan Misali"}, "video": {"id": "qID2B4MK7Y0", "views": 1272282, "title": "a better way to count"}}
{"creator": {"handle": "HBMmaster", "display_name": "jan Misali"}, "video": {"id": "2EZihKCB9iw", "views": 272019, "title": "what is toki pona? (toki pona lesson one)"}}
{"creator": {"handle": "SarahZ", "display_name": "Sarah Z"}, "video": {"id": "ohFyOjfcLWQ", "views": 3115062, "title": "A Brief History of Homestuck"}}
"""

let jsonl = parseJsonLines(data)

echo jsonl[3] # retrieve value

jsonl[3] = %* {
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

echo jsonl[3] # echo new value
```

## other stuff (i guess)

Im really tired ill fix this whenever i feel a bit better.

Anyways, heres some of the other stuff in this library:

- `pretty()`: Prettifies JsonLines JsonLines by making it easier to view. However, this results in invalid JSON Lines.

- `add()`: Add JsonNode to JsonLines object

- `toJArray()`: Convert JsonLines into JSON array (JArray)

- `toJsonLines()`: Convert openArray of JsonNodes to JsonLines

- `jsonLines()`: Convenience iterator that parses string buffer line by line
