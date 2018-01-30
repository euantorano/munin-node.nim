## A plugin to show the number of processes and threads in the system.

import ../plugin

when defined(windows):
  include ./processes/processes_windows
else:
  {.error: "The uptime plugin does not support your OS".}

const
  ProcessesPluginName* = "processes"

proc initProcessesPlugin*(): Plugin =
  ## Create a new instance of the processes plugin to get the current process and thread statistics.
  result = initPlugin(ProcessesPluginName, GetConfigFunction(processesConfig), GetValuesFunction(processesValues))