# Package

version       = "0.1.0"
author        = "Jasmine"
description   = "Simple JSON Lines parser in Nim"
license       = "MIT"
srcDir        = "src"


# Tasks

task docs, "Build docs for jsonlines":
  # nim docs
  selfExec "doc src/jsonlines.nim"

  # nimib docs
  cpFile "tests/data/1.jsonl", "docsrc/1.jsonl" # copy example JSON Lines file
  selfExec "c -r docsrc/index.nim" # generate html docs
  selfExec "c -d:readme -r docsrc/index.nim" # generate readme


# Dependencies

requires "nim >= 1.4.0"

# "Error: undeclared identifier: 'taskRequires'" MY ASS
when false:
  taskRequires "docs", "https://github.com/neroist/jsonlines"
  taskRequires "docs", "nimoji"
  taskRequires "docs", "nimib"
