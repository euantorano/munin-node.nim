## A plugin to show what the machine uses its memory for.

import ../plugin

import winlean, os

const
  MemoryPluginName* = "memory"

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
  DWORDLONG = uint64

  MEMORYSTATUSEX {.incompleteStruct.} = object
    dwLength: DWORD
    dwMemoryLoad: DWORD
    ullTotalPhys: DWORDLONG
    ullAvailPhys: DWORDLONG
    ullTotalPageFile: DWORDLONG
    ullAvailPageFile: DWORDLONG
    ullTotalVirtual: DWORDLONG
    ullAvailVirtual: DWORDLONG
    ullAvailExtendedVirtual: DWORDLONG

  LPMEMORYSTATUSEX = ptr MEMORYSTATUSEX

proc memoryConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = MemoryPluginConfig

proc GlobalMemoryStatusEx(lpBuffer: LPMEMORYSTATUSEX): WINBOOL {.stdcall, dynlib: "kernel32", importc: "GlobalMemoryStatusEx".}
  ## Retrieves information about the system's current usage of both physical and virtual memory.

proc memoryValues(plugin: Plugin): string =
  ## Get the plugin values.
  var mem: MEMORYSTATUSEX
  mem.dwLength = DWORD(sizeof(mem))

  if GlobalMemoryStatusEx(addr mem) == 0:
    raiseOSError(osLastError())

  result = "apps.value " & $(mem.ullTotalPhys - mem.ullAvailPhys) & "\L" &
    "swap.value " & $(mem.ullTotalPageFile - mem.ullAvailPageFile) & "\L" &
    "free.value " & $mem.ullAvailPhys & "\L" &
    ".\L"

proc initMemoryPlugin*(): Plugin =
  ## Create a new instance of the memory plugin to get current system memory status.
  result = initPlugin(MemoryPluginName, GetConfigFunction(memoryConfig), GetValuesFunction(memoryValues))

# TODO: A macro that builds a table of plugins for easy lookup and access