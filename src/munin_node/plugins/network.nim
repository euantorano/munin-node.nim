## A plugin to show the traffic of the network interfaces. Please note that the traffic is shown in packets per second, not bytes.

import ../plugin

when defined(windows):
  include ./network/network_windows
else:
  {.warning: "The network plugin does not support your OS".}

  proc networkConfig(p: Plugin) : string = ""

  proc networkValues(p: Plugin): string = ""

const
  NetworkPluginName* = "network"

type
  NetworkPlugin* = ref NetworkPluginObj
    ## A plugin to show the traffic of the network interfaces.

  NetworkPluginObj* = object of PluginObj
    ## A plugin to show the traffic of the network interfaces.

proc newNetworkPlugin*(): NetworkPlugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = NetworkPlugin(
    name: NetworkPluginName,
    configFunction: networkConfig,
    valuesFunction: networkValues
  )
