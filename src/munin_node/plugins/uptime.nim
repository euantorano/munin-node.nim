## A plugin to show the uptime of the system in days. Note that uptime on Windows versions >= 8 may be broken by the "fast startup" feature.

import ../plugin

when defined(windows):
  include ./uptime/uptime_windows
elif defined(posix):
  include ./uptime/uptime_posix
else:
  {.error: "The uptime plugin does not support your OS".}

const
  UptimePluginName* = "uptime"

type
  UptimePlugin* = ref UptimePluginObj
    ## A plugin to show the traffic of the network interfaces.

  UptimePluginObj* = object of PluginObj
    ## A plugin to show the traffic of the network interfaces.

proc newUptimePlugin*(): UptimePlugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = UptimePlugin(
    name: UptimePluginName,
    configFunction: uptimeConfig,
    valuesFunction: uptimeValues
  )
