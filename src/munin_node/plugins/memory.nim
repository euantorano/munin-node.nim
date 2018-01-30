## A plugin to show what the machine uses its memory for.

import ../plugin

when defined(windows):
  include ./memory/memory_windows
else:
  {.error: "The memory plugin does not support your OS".}

const
  MemoryPluginName* = "memory"

proc initMemoryPlugin*(): Plugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = initPlugin(MemoryPluginName, GetConfigFunction(memoryConfig), GetValuesFunction(memoryValues))
