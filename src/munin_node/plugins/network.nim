## A plugin to show the traffic of the network interfaces. Please note that the traffic is shown in packets per second, not bytes.

import ../plugin

when defined(windows):
  include ./network/network_windows
else:
  {.error: "The network plugin does not support your OS".}

const
  NetworkPluginName* = "network"

proc initNetworkPlugin*(): Plugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = initPlugin(NetworkPluginName, GetConfigFunction(memoryConfig), GetValuesFunction(memoryValues))