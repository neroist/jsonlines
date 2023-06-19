import std/enumerate
import std/strutils
import std/streams
import std/json

type
  JsonLines = ref object
    nodes*: seq[JsonNode]

proc parseJsonLines*(buffer: string; rawIntegers = false, rawFloats = false): JsonLines = 
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

  new result
  
  for lineno, line in enumerate(1, buffer.splitLines()):
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

proc parseJsonLines*(s: Stream, filename: string = "input"; rawIntegers = false, rawFloats = false): JsonLines = 
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
  
  new result

  var 
    line: string
    lineno: int = 1

  while s.readLine(line):
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

iterator jsonLines*(buffer: string; rawIntegers = false, rawFloats = false): JsonNode = 
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
  
  for lineno, line in enumerate(1, buffer.splitLines()):
    when defined(js):
      yield parseJson('\n'.repeat(lineno - 1) & line)
    else:
      yield parseJson('\n'.repeat(lineno - 1) & line, rawIntegers, rawFloats)

export json
