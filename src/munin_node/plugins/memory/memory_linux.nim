## A plugin to show what the machine uses its memory for.
##
## This is a linux specific implementation, using the `sysinfo` function.

import ../../plugin

import posix, os, strutils

const
  MemoryPluginConfig = "graph_args --base 1024 -l 0 --vertical-label Bytes --upper-limit 329342976\L" &
    "graph_title Memory usage\L" &
    "graph_category system\L" &
    "graph_info This graph shows what the machine uses its memory for.\L" &
    "graph_order apps free swap\L" &
    "apps.label apps\L" &
    "apps.draw AREA\L" &
    "apps.info Memory used by user-space applications.\L" &
    "swap.label swap\L" &
    "swap.draw STACK\L" &
    "swap.info Swap space used.\L" &
    "free.label unused\L" &
    "free.draw STACK\L" &
    "free.info Wasted memory. Memory that is not used for anything at all.\L" &
    ".\L"

type
  SysInfo {.importc: "struct sysinfo", header: "<sys/sysinfo.h>", final, pure.} = object
    totalram: culong
      ## Total usable main memory size.
    freeram: culong
      ## Available memory size.
    sharedram: culong
      ## Amount of shared memory.
    bufferram: culong
      ## Memory used by buffers.
    totalswap: culong
      ## Total swap space size.
    freeswap: culong
      ## Swap space still available.

proc memoryConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = MemoryPluginConfig

proc sysinfo(info: ptr SysInfo): cint {.importc: "sysinfo", header: "<sys/sysinfo.h>".}

proc memoryValues(plugin: Plugin): string =
  ## Get the plugin values.
  var info: SysInfo

  if sysinfo(addr info) != 0:
    raiseOSError(osLastError())

  result = "apps.value " & $(info.totalram - info.freeram) & "\L" &
    "swap.value " & $(info.totalswap - info.freeswap) & "\L" &
    "free.value " & $info.freeram & "\L" &
    ".\L"
