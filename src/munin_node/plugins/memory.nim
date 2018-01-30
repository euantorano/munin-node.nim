## A plugin to show what the machine uses its memory for.

import ../plugin

when defined(windows):
  include ./memory/memory_windows
else:
  {.error: "The memory plugin does not support your OS".}

const
  MemoryPluginName* = "memory"

type
  MemoryPlugin* = ref MemoryPluginObj
    ## A plugin to show what the machine uses its memory for.

  MemoryPluginObj* = object of PluginObj
    ## A plugin to show what the machine uses its memory for.

proc newMemoryPlugin*(): MemoryPlugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = MemoryPlugin(
    name: MemoryPluginName,
    configFunction: memoryConfig,
    valuesFunction: memoryValues
  )
