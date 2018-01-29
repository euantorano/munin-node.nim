## A plugin to show the traffic of the network interfaces. Please note that the traffic is shown in packets per second, not bytes.

import ../plugin

import winlean, os

const
  NetworkPluginName* = "network"

  NetworkPluginConfig = "graph_order down up\L" &
    "graph_title network traffic\L" &
    "graph_args --base 1000\L" &
    "graph_vlabel packets in (-) / out (+) per ${graph_period}\L" &
    "graph_category network\L" &
    "graph_info This graph shows the traffic of the network interfaces. Please note that the traffic is shown in packets per second, not bytes.\L" &
    "down.label pps\L" &
    "down.type COUNTER\L" &
    "down.graph no\L" &
    "up.label pps\L" &
    "up.type COUNTER\L" &
    "up.negative down\L" &
    "up.info Traffic of the interfaces. Maximum speed is 54000000 packets per second.\L" &
    "up.max 54000000\L" &
    "down.max 54000000\L" &
    ".\L"

type
  MIB_TCPSTATS {.importc: "MIB_TCPSTATS", header: "Iphlpapi.h", incompleteStruct.} = object
    dwRtoAlgorithm: DWORD
    dwRtoMin: DWORD
    dwRtoMax: DWORD
    dwMaxConn: DWORD
    dwActiveOpens: DWORD
    dwPassiveOpens: DWORD
    dwAttemptFails: DWORD
    dwEstabResets: DWORD
    dwCurrEstab: DWORD
    dwInSegs: DWORD
    dwOutSegs: DWORD
    dwRetransSegs: DWORD
    dwInErrs: DWORD
    dwOutRsts: DWORD
    dwNumConns: DWORD

  PMIB_TCPSTATS = ptr MIB_TCPSTATS

  MIB_UDPSTATS {.importc: "MIB_UDPSTATS", header: "Iphlpapi.h", incompleteStruct.} = object
    dwInDatagrams: DWORD
    dwNoPorts: DWORD
    dwInErrors: DWORD
    dwOutDatagrams: DWORD
    dwNumAddrs: DWORD

  PMIB_UDPSTATS = ptr MIB_UDPSTATS

proc memoryConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = NetworkPluginConfig

proc GetTcpStatisticsEx(pStats: PMIB_TCPSTATS, dwFamily: DWORD): DWORD {.stdcall, dynlib: "Iphlpapi", importc: "GetTcpStatistics".}
  ## The GetTcpStatisticsEx function retrieves the Transmission Control Protocol (TCP) statistics for the current computer.
  ## The GetTcpStatisticsEx function differs from the GetTcpStatistics function in that GetTcpStatisticsEx also supports the Internet Protocol version 6 (IPv6) protocol family.

proc GetUdpStatisticsEx(pStats: PMIB_UDPSTATS, dwFamily: DWORD): DWORD {.stdcall, dynlib: "Iphlpapi", importc: "GetUdpStatisticsEx".}
  ## The GetUdpStatisticsEx function retrieves the User Datagram Protocol (UDP) statistics for the current computer.
  ## The GetUdpStatisticsEx function differs from the GetUdpStatistics function in that GetUdpStatisticsEx also supports the Internet Protocol version 6 (IPv6) protocol family. 

proc memoryValues(plugin: Plugin): string =
  ## Get the plugin values.
  var tcp4Stats: MIB_TCPSTATS
  var tcp6Stats: MIB_TCPSTATS
  var udp4Stats: MIB_UDPSTATS
  var udp6Stats: MIB_UDPSTATS

  if GetTcpStatisticsEx(addr tcp4Stats, AF_INET) != NO_ERROR:
    raiseOSError(osLastError())

  if GetTcpStatisticsEx(addr tcp6Stats, AF_INET6) != NO_ERROR:
    raiseOSError(osLastError())

  if GetUdpStatisticsEx(addr udp4Stats, AF_INET) != NO_ERROR:
    raiseOSError(osLastError())

  if GetUdpStatisticsEx(addr udp6Stats, AF_INET6) != NO_ERROR:
    raiseOSError(osLastError())

  result = "down.value " & $(tcp4Stats.dwInSegs + tcp6Stats.dwInSegs + udp4Stats.dwInDatagrams + udp6Stats.dwInDatagrams) & "\L" &
    "up.value " & $(tcp4Stats.dwOutSegs + tcp6Stats.dwOutSegs + udp4Stats.dwOutDatagrams + udp6Stats.dwOutDatagrams) & "\L" &
    ".\L"

proc initNetworkPlugin*(): Plugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = initPlugin(NetworkPluginName, GetConfigFunction(memoryConfig), GetValuesFunction(memoryValues))

# TODO: A macro that builds a table of plugins for easy lookup and access