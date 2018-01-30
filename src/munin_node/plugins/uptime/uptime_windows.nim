## A plugin to show the uptime of the system in days. Note that uptime on Windows versions >= 8 may be broken by the "fast startup" feature.
##
## This is a windows specific implementation, using the `GetTickCount64` function.

import ../../plugin

import winlean, os, strutils

const
  UptimePluginConfig = "graph_title Uptime\L" &
    "graph_category system\L" &
    "graph_args --base 1000 -l 0\L" &
    "graph_vlabel uptime in days\L" &
    "uptime.label uptime\L" &
    "uptime.draw AREA\L" &
    ".\L"

  DayInMilliseconds: float64 = float64(1000 * 60 * 60 * 24)

proc uptimeConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = UptimePluginConfig

proc GetTickCount64(): uint64 {.stdcall, dynlib: "kernel32", importc: "GetTickCount64".}

proc uptimeValues(plugin: Plugin): string =
  ## Get the plugin values.
  let uptimeMilliseconds = GetTickCount64()

  if uptimeMilliseconds == 0:
    result = ".\L"
  else:
    let uptimeDays = float64(uptimeMilliseconds) / DayInMilliseconds

    result = "uptime.value " & formatBiggestFloat(uptimeDays, format=ffDecimal, precision=2) & "\L.\L"
