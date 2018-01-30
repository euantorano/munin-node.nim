## A munin node implementation written in Nim, primarily designed to run on Windows nodes.

import munin_node/server

import asyncdispatch, logging

proc initLogging() =
  ## Initialise logging handlers to log information about the munin node's status.
  var console = newConsoleLogger(fmtStr=verboseFmtStr)

  addHandler(console)

proc main() =
  # TODO: configuration, windows sevrice, command line handling, etc.
  initLogging()

  let server = initServer()

  waitFor server.run()

main()
