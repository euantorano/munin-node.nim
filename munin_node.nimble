# Package

version       = "0.1.0"
author        = "Euan T"
description   = "A munin node implementation written in Nim, primarily designed to run on Windows nodes."
license       = "BSD-3-Clause"

srcDir = "src"

bin = @["munin_node"]

# Dependencies

requires "nim >= 0.17.2"

