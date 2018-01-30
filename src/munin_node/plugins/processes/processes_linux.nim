## A plugin to show the number of processes and threads in the system.
##
## This is a linux specific implementation, using the `sysinfo` function.

import ../../plugin

import posix, os, strutils

const
  ProcessesPluginConfig = "graph_title Number of Processes\L" &
    "graph_args --base 1000 -l 0\L" &
    "graph_vlabel number of processes\L" &
    "graph_category processes\L" &
    "graph_info This graph shows the number of processes and threads in the system.\L" &
    "processes.label processes\L" &
    "processes.draw LINE2\L" &
    "processes.info The current number of processes.\L" &
    "threads.label threads\L" &
    "threads.draw LINE1\L" &
    "threads.info The current number of threads.\L" &
    ".\L"

type
  SysInfo {.importc: "struct sysinfo", header: "<sys/sysinfo.h>", final, pure.} = object
    procs: cushort
      ## Number of current processes.

proc processesConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = ProcessesPluginConfig

proc sysinfo(info: ptr SysInfo): cint {.importc: "sysinfo", header: "<sys/sysinfo.h>".}

proc processesValues(plugin: Plugin): string =
  ## Get the plugin values.
  var info: SysInfo

  if sysinfo(addr info) != 0:
    raiseOSError(osLastError())

  result = "processes.value " & $info.procs & "\L" &
    "threads.value 0\L" &
    ".\L"
