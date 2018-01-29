## A plugin to show the number of processes and threads in the system.

import ../plugin

import winlean, os

const
  ProcessesPluginName* = "processes"

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

var
  TH32CS_SNAPPROCESS: DWORD = 0x00000002
    ## Includes all processes in the system in the snapshot.

type
  ProcessesPlugin* = object

  PROCESSENTRY32 {.incompleteStruct.} = object
    dwSize: DWORD
    cntUsage: DWORD
    th32ProcessID: DWORD
    th32DefaultHeapID: ULONG_PTR
    th32ModuleID: DWORD
    cntThreads: DWORD
    th32ParentProcessID: DWORD
    pcPriClassBase: clong
    dwFlags: DWORD
    szExeFile: array[MAX_PATH, cchar]

proc processesConfig(plugin: Plugin): string =
  ## Get the plugin graph configuration.
  result = ProcessesPluginConfig

proc CreateToolhelp32Snapshot(dwFlags: DWORD, th32ProcessID: DWORD): HANDLE {.stdcall, dynlib: "kernel32", importc: "CreateToolhelp32Snapshot".}
  ## Takes a snapshot of the specified processes, as well as the heaps, modules, and threads used by these processes.

proc Process32First(hSnapshot: HANDLE, lppe: ptr PROCESSENTRY32): WINBOOL {.stdcall, dynlib: "kernel32", importc: "Process32First".}
  ## Retrieves information about the first process encountered in a system snapshot.

proc Process32Next(hSnapshot: HANDLE, lppe: ptr PROCESSENTRY32): WINBOOL {.stdcall, dynlib: "kernel32", importc: "Process32Next".}
  ## Retrieves information about the next process recorded in a system snapshot.

proc processesValues(plugin: Plugin): string =
  ## Get the plugin values.
  var
    numProcesses = 0
    numThreads = 0

  let snapShot: HANDLE = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  if snapShot != INVALID_HANDLE_VALUE:
    try:
      var entry: PROCESSENTRY32
      entry.dwSize = DWORD(sizeof(entry))

      var success = Process32First(snapShot, addr entry)

      if success == 0:
        raiseOSError(osLastError())

      while success != 0:
        inc(numProcesses, 1)
        inc(numThreads, int(entry.cntThreads))

        success = Process32Next(snapShot, addr entry)
    finally:
      discard closeHandle(snapShot)
  else:
    raiseOSError(osLastError())

  result = "processes.value " & $numProcesses & "\Lthreads.value " & $numThreads & "\L.\L" 

proc initProcessesPlugin*(): Plugin =
  ## Create a new instance of the processes plugin to get the current process and thread statistics.
  result = initPlugin(ProcessesPluginName, GetConfigFunction(processesConfig), GetValuesFunction(processesValues))

# TODO: A macro that builds a table of plugins for easy lookup and access