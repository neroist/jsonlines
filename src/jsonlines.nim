##[ 
  This is a simple library which implements a simple 
  [JSON Lines](https://jsonlines.org/) parser (also known as NDJSON or 
  newline-delimited JSON).

  JSON Lines is a file format similar to JSON, except it can hold multiple 
  JSON documents in a single file, which are delimited by newlines. It's a
  convenient format for storing structured data that may be processed one
  record at a time and works well with unix-style text processing tools and
  shell pipelines. It's also a great format for log files, and a flexible 
  format for passing messages between cooperating processes. 

  This format has three main requirements:

  1. **UTF-8 Encoding.** (although this library doesn't check for that)
  2. **Each line is a valid JSON value.**
     The most common values will be objects or arrays, although any JSON
     value is permitted. However, with this library, you can also choose 
     whether or not to ignore empty lines.
  3. **Line Separator is '\\n'.** '\\r\\n' is also supported because
     surrounding white space is implicitly ignored when parsing JSON values. 

  Examples:
  
  ```jsonl
  {"name": "Gilbert", "wins": [["straight", "7♣"], ["one pair", "10♥"]]}
  {"name": "Alexa", "wins": [["two pair", "4♠"], ["two pair", "9♠"]]}
  {"name": "May", "wins": []}
  {"name": "Deloise", "wins": [["three of a kind", "5♣"]]}
  ```
  ```jsonl
  {"some": "thing"}
  {"foo": 17, "bar": false, "quux": true}
  {"may": {"include": "nested", "objects": ["and", "arrays"]}}
  ```

  # Parsing JSON Lines
  
  To parse JSON Lines data, all you simply have to do is use the 
  [parseJsonLines](#parseJsonLines%2Cstring%2Cbool) proc.

  ```nim
  import jsonlines

  let jsonl = parseJsonLines"""{"some": "thing"}
  {"foo": 17, "bar": false, "quux": true}
  {"may": {"include": "nested", "objects": ["and", "arrays"]}}
  """

  echo jsonl
  ```

  This parses the data into a simple `JsonLines` object, which has a `nodes`
  attribute, containing a seq of all the 
  [JsonNodes](https://nim-lang.org/docs/json.html#JsonNode) in the document.

  This proc also works with Streams!

  ## Parsing from a file

  .. note:: This functionality is not supported on the JS backend

  To parse from a file, you can:
    1. Read the file and use [parseJsonLines](#parseJsonLines%2Cstring%2Cbool)
    2. Create the file stream yourself and use 
       [parseJsonLines](#parseJsonLines%2CStream%2Cstring%2Cbool)
    3. Simply call [parseJsonLinesFile](#parseJsonLinesFile%2Cstring) with the 
       name/location of the file.

  Example for #3:
  
  **Example file 1.jsonl:**
  ```jsonl
  ["Name", "Session", "Score", "Completed"]
  ["Gilbert", "2013", 24, true]
  ["Alexa", "2013", 29, true]
  ["May", "2012B", 14, false]
  ["Deloise", "2012A", 19, true]
  ```

  **Nim code:**
  ```nim
  import jsonlins

  echo parseJsonLinesFile("./1.jsonl")
  ```
]##

import std/enumerate
import std/strutils
import std/streams
import std/json

type
  JsonLines = ref object
    nodes*: seq[JsonNode]

proc parseJsonLines*(buffer: string; rawIntegers = false, rawFloats = false; ignoreEmptyLines: bool = true): JsonLines = 
  ## Parses JSON Lines from `buffer`.
  ## 
  ## If `buffer` contains extra data, it will raise `JsonParsingError`.
  ## 
  ## The `rawIntegers` and `rawFloats` parameters are the same as the ones
  ## in [parseJson](https://nim-lang.org/docs/json.html#parseJson%2Cstring)
  ## 
  ## .. note:: On the JS backend, these parameters are ignored.
  ## 
  ## :buffer: The string of Json Lines data to parse
  ## :rawIntegers: If true, integer literals will not be converted to a
  ##              `JInt` field but kept as raw numbers via `JString`.
  ## :rawFloats: If is true, floating point literals will not be converted
  ##             to a `JFloat` field but kept as raw numbers via `JString`.
  ## :ignoreEmptyLines: Whether or not to ignore empty lines in the buffer.

  new result
  
  for lineno, line in enumerate(1, buffer.splitLines()):
    if (line.len == 0 or line in ["\n", "\r\n"]) and ignoreEmptyLines:
      continue
    
    when defined(js):
      # JS backend does not support `rawIntegers` and `rawFloats` params

      result.nodes.add parseJson(
        '\n'.repeat(lineno - 1) & line, # results in correct line numbers for err msgs
      )
    else:
      result.nodes.add parseJson(
        '\n'.repeat(lineno - 1) & line,
        rawIntegers, 
        rawFloats
      )

proc parseJsonLines*(s: Stream, filename: string = "input"; rawIntegers = false, rawFloats = false; ignoreEmptyLines: bool = true): JsonLines = 
  ## Parses from a stream `s` into `JsonLines`. `filename` is only needed
  ## for nice error messages.
  ## 
  ## If `s` contains extra data, it will raise `JsonParsingError`.
  ## 
  ## The `rawIntegers` and `rawFloats` parameters are the same as the ones
  ## in [parseJson](https://nim-lang.org/docs/json.html#parseJson%2Cstring)
  ## 
  ## .. note:: On the JS backend, these parameters are ignored.
  ## 
  ## :s: The stream of Json Lines data to parse
  ## :rawIntegers: If true, integer literals will not be converted to a
  ##              `JInt` field but kept as raw numbers via `JString`.
  ## :rawFloats: If is true, floating point literals will not be converted
  ##             to a `JFloat` field but kept as raw numbers via `JString`.
  ## :ignoreEmptyLines: Whether or not to ignore empty lines in the stream `s`.
  
  new result

  var 
    line: string
    lineno: int = 1

  while s.readLine(line):
    if (line.len == 0 or line in ["\n", "\r\n"]) and ignoreEmptyLines:
      continue
    
    result.nodes.add parseJson(
      newStringStream('\n'.repeat(lineno - 1) & line), # better error msgs, correct line numbers
      filename, 
      rawIntegers, 
      rawFloats
    )

    inc lineno

when not defined(js):
  # FileStream object is not available on JS backend
  # nor is `readFile`

  proc parseJsonLinesFile*(filename: string): JsonLines =
    ## Parses `file` into `JsonLines`.
    ## 
    ## If `file` contains extra data, it will raise `JsonParsingError`.
    ## 
    ## .. warning:: This proc is not defined for the JS backend
    
    var stream = newFileStream(filename)

    if stream == nil:
      raise newException(IOError, "cannot read from file: " & filename)
    
    result = parseJsonLines(stream, filename, rawIntegers=false, rawFloats=false)
 
proc `$`*(jsonl: JsonLines): string =
  ## Convert JsonLines into a string
  
  for node in jsonl.nodes:
    result.add $node

    if node != jsonl.nodes[^1]:
      result.add '\n'

proc pretty*(jsonl: JsonLines, indent: int = 2): string =
  ## Prettifies JsonLines `jsonl` by making it easier to view.
  ## 
  ## However, this results in invalid JsonLines, unable to be parsed.
  ## 
  ## :jsonl: The JsonLines to prettify (or beautify)
  ## :indent: How muuch to indent, in spaces

  for node in jsonl.nodes:
    result.add node.pretty(indent)

    if node != jsonl.nodes[^1]:
      result.add '\n'

proc toJArray*(jsonl: JsonLines): JsonNode =
  ## Convert JsonLines to a JArray

  result = newJArray()
  result.elems = jsonl.nodes

proc toJsonLines*(nodes: openArray[JsonNode]): JsonLines = 
  ## Convert open array of JsonNodes to JsonLines
  
  new result

  result.nodes = @nodes # to seq operator

proc add*(jsonl: JsonLines, node: JsonNode) =
  ## Add JsonNode to JsonLines `jsonl`
  ## 
  ## :jsonl: The JsonLines object to add the node to
  ## :node: The JsonNode to add 

  jsonl.nodes.add node

proc `[]`*(jsonl: JsonLines, idx: int): JsonNode =
  ## Get JSON node in JsonLines `jsonl` at index `idx`
  ## 
  ## :jsonl: The JsonLines object to get the node from
  ## :idx: The index of the JsonNode to retrieve
  
  jsonl.nodes[idx]

proc `[]=`*(jsonl: JsonLines, idx: int, val: JsonNode) =
  ## Assign JSON node in JsonLines `jsonl` at index `idx`
  ## 
  ## :jsonl: The JsonLines object to get the node from
  ## :idx: The index of the JsonNode to retrieve
  ## :val: The node to assign the index to

  jsonl.nodes[idx] = val

iterator items*(jsonl: JsonLines): JsonNode =
  for node in jsonl.nodes:
    yield node

iterator mitems*(jsonl: var JsonLines): JsonNode =
  for node in jsonl.nodes:
    yield node

iterator pairs*(jsonl: JsonLines): tuple[idx: int, node: JsonNode] =
  for idx, node in jsonl.nodes:
    yield (idx, node)

iterator mpairs*(jsonl: var JsonLines): tuple[idx: int, node: var JsonNode] =
  for idx, _ in jsonl.nodes:
    yield (idx, jsonl.nodes[idx])

iterator jsonLines*(buffer: string; rawIntegers = false, rawFloats = false; ignoreEmptyLines: bool = true): JsonNode = 
  ## Convinience iterator to iterate through the JSON values in JsonLines 
  ## document `buffer`
  ## 
  ## The `rawIntegers` and `rawFloats` parameters are the same as the ones
  ## in [parseJson](https://nim-lang.org/docs/json.html#parseJson%2Cstring)
  ## 
  ## .. note:: On the JS backend, these parameters are ignored.
  ## 
  ## :buffer: The string of Json Lines data to parse
  ## :rawIntegers: If true, integer literals will not be converted to a
  ##              `JInt` field but kept as raw numbers via `JString`.
  ## :rawFloats: If is true, floating point literals will not be converted
  ##             to a `JFloat` field but kept as raw numbers via `JString`.
  ## :ignoreEmptyLines: Whether or not to ignore empty lines in the buffer.
  
  for lineno, line in enumerate(1, buffer.splitLines()):
    if (line.len == 0 or line in ["\n", "\r\n"]) and ignoreEmptyLines:
      continue    
    
    when defined(js):
      yield parseJson('\n'.repeat(lineno - 1) & line)
    else:
      yield parseJson('\n'.repeat(lineno - 1) & line, rawIntegers, rawFloats)

export json
