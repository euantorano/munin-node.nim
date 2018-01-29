## A munin node implementation written in Nim, primarily designed to run on Windows nodes.

import munin_node/server

import asyncdispatch

proc main() =
  # TODO: configuration, windows sevrice, command line handling, etc.

  let server = initServer()

  waitFor server.run()

main()