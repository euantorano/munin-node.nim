## A plugin to show the uptime of the system in days. Note that uptime on Windows versions >= 8 may be broken by the "fast startup" feature.
##
## This is a POSIX specific implementation, using `sysctl` with `KERN_BOOTTIME`.

import ../../plugin

import posix, os, times

const
  UptimePluginConfig = "graph_title Uptime\L" &
    "graph_category system\L" &
    "graph_args --base 1000 -l 0\L" &
    "graph_vlabel uptime in days\L" &
    "uptime.label uptime\L" &
    "uptime.draw AREA\L" &
    ".\L"

var
  CTL_KERN {.importc: "CTL_KERN", header: "<sys/sysctl.h>".}: cint
  KERN_BOOTTIME {.importc: "KERN_BOOTTIME", header: "<sys/sysctl.h>".}: cint

proc uptimeConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = UptimePluginConfig

proc sysctl(name: pointer, namelen: cuint, oldp: ptr Timespec, oldlenp: ptr cint, newp: pointer, newlen: cint): cint {.importc: "sysctl", header: "<sys/sysctl.h>".}

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
