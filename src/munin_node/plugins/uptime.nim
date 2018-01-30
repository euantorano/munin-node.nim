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

proc initUptimePlugin*(): Plugin =
  ## Create a new instance of the uptime plugin to get the uptime of the system.
  result = initPlugin(UptimePluginName, GetConfigFunction(uptimeConfig), GetValuesFunction(uptimeValues))