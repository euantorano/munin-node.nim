## A plugin to show the uptime of the system in days. Note that uptime on Windows versions >= 8 may be broken by the "fast startup" feature.

import ../plugin

import winlean, posix, os, strutils, times

const
  UptimePluginName* = "uptime"

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

when defined(windows):
  proc GetTickCount64(): uint64 {.stdcall, dynlib: "kernel32", importc: "GetTickCount64".}

  proc uptimeValues(plugin: Plugin): string =
    ## Get the plugin values.
    let uptimeMilliseconds = GetTickCount64()

    if uptimeMilliseconds == 0:
      result = ".\L"
    else:
      let uptimeDays = float64(uptimeMilliseconds) / DayInMilliseconds

      result = "uptime.value " & formatBiggestFloat(uptimeDays, format=ffDecimal, precision=2) & "\L.\L"
elif defined(linux):
  proc uptimeValues(plugin: Plugin): string =
    ## Get the plugin values.
    result = "uptime.value 0.00\L.\L"
elif defined(posix):
  var
    CTL_KERN {.importc: "CTL_KERN", header: "<sys/sysctl.h>".}: cint
    KERN_BOOTTIME {.importc: "KERN_BOOTTIME", header: "<sys/sysctl.h>".}: cint

  proc sysctl(name: pointer, namelen: cuint, oldp: ptr Timespec, oldlenp: ptr cint, newp: pointer, newlen: cint): cint {.importc: "sysctl", header: "sys/sysctl.h".}

  proc uptimeValues(plugin: Plugin): string =
    ## Get the plugin values.
    var bootTime: Timespec
    var nameLen: cint = cint(sizeof(bootTime))
    var mib: array[2, cint] = [CTL_KERN, KERN_BOOTTIME]

    if sysctl(addr mib[0], 2, addr bootTime, addr nameLen, nil, 0) < 0:
      raiseOSError(osLastError())

    let currentTime = getTime()

    let uptime = toTimeInterval(bootTime.tv_sec) - toTimeInterval(currentTime)

    result = "uptime.value " & $uptime.days & "\L.\L"
else:
  {.error: "Uptime plugin is not implemented for your OS".}

proc initUptimePlugin*(): Plugin =
  ## Create a new instance of the uptime plugin to get the uptime of the system.
  result = initPlugin(UptimePluginName, GetConfigFunction(uptimeConfig), GetValuesFunction(uptimeValues))

# TODO: A macro that builds a table of plugins for easy lookup and access