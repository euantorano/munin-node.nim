## A plugin to show the uptime of the system in days. Note that uptime on Windows versions >= 8 may be broken by the "fast startup" feature.
##
## This is a linux specific implementation, using the `sysinfo` function.

import ../../plugin

import posix, os, strutils

const
  UptimePluginConfig = "graph_title Uptime\L" &
    "graph_category system\L" &
    "graph_args --base 1000 -l 0\L" &
    "graph_vlabel uptime in days\L" &
    "uptime.label uptime\L" &
    "uptime.draw AREA\L" &
    ".\L"

  DayInSeconds: float64 = float64(60 * 60 * 24)

type
  SysInfo {.importc: "struct sysinfo", header: "<sys/sysinfo.h>", final, pure.} = object
    uptime: clong
      ## Seconds since boot.

proc uptimeConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = UptimePluginConfig

proc sysinfo(info: ptr SysInfo): cint {.importc: "sysinfo", header: "<sys/sysinfo.h>".}

proc uptimeValues(plugin: Plugin): string =
  ## Get the plugin values.
  var info: SysInfo

  if sysinfo(addr info) != 0:
    raiseOSError(osLastError())

  if info.uptime == 0:
    result = ".\L"
  else:
    let uptimeDays = float64(info.uptime) / DayInSeconds

    result = "uptime.value " & formatBiggestFloat(uptimeDays, format=ffDecimal, precision=2) & "\L.\L"
