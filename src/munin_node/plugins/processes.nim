## A plugin to show the number of processes and threads in the system.

import ../plugin

when defined(windows):
  include ./processes/processes_windows
else:
  {.error: "The uptime plugin does not support your OS".}

const
  ProcessesPluginName* = "processes"

type
  ProcessesPlugin* = ref ProcessesPluginObj
    ## A plugin to show the traffic of the network interfaces.

  ProcessesPluginObj* = object of PluginObj
    ## A plugin to show the traffic of the network interfaces.

proc newProcessesPlugin*(): ProcessesPlugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = ProcessesPlugin(
    name: ProcessesPluginName,
    configFunction: processesConfig,
    valuesFunction: processesValues
  )
