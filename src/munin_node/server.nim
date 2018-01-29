## Server to accept incoming connections from a munin master.

import ./utils, ./plugin, ./plugins/processes, ./plugins/memory, ./plugins/network, ./plugins/uptime

import asyncdispatch, asyncnet, nativesockets

const
  DefaultListenAddress* = 4949'u16
    ## The default listen address to listen for incoming connections on.

  BufferSize* = 4 * 1024 * 1024
    ## The receive buffer size.

  UnknownCommandResponse = "# Unknown command. Try list, nodes, config, fetch, version or quit\L"
    ## Response sent to a connected client when a command is not recognised.

  UnknownServiceResponse = "# Unknown service\L.\L"
    ## Response sent to a connected client when a service is not recognised.

  UnknownErrorResponse = "# Unknown Error\L.\L"
    ## Response sent to a connected client when an unknown error occurs.

type
  Server* = object
    sock: AsyncSocket
    listen: bool
    hostname: string

proc initServer*(port: uint16 = DefaultListenAddress, hostname: string = ""): Server =
  ## Intiailise a new server and bind it, ready to accept incoming connections.
  result = Server(
    sock: newAsyncSocket(),
    listen: true,
    hostname: if len(hostname) == 0: getHostname() else: hostname
  )

  result.sock.setSockOpt(OptReuseAddr, true)
  result.sock.bindAddr(Port(port))
  result.sock.listen()

  echo "Server started listening on port ", port, " with hostname: ", result.hostname

proc processFetchRequest(request: string): string =
  let startIndex = if len(request) > 6 and request[5] == ' ': 6 else: 5
  let requestedConfig = request[startIndex..^1]

  var plugin: Plugin

  case requestedConfig
  of ProcessesPluginName:
    plugin = initProcessesPlugin()
  of MemoryPluginName:
    plugin = initMemoryPlugin()
  of NetworkPluginName:
    plugin = initNetworkPlugin()
  of UptimePluginName:
    plugin = initUptimePlugin()
  else:
    result = UnknownServiceResponse
    return

  try:
    result = plugin.values()
  except:
    echo "Unknown exception ", repr(getCurrentException()) , ": ", getCurrentExceptionMsg()

    result = UnknownErrorResponse

proc processConfigRequest(request: string): string =
  let startIndex = if len(request) > 7 and request[6] == ' ': 7 else: 6
  let requestedConfig = request[startIndex..^1]

  var plugin: Plugin

  case requestedConfig
  of ProcessesPluginName:
    plugin = initProcessesPlugin()
  of MemoryPluginName:
    plugin = initMemoryPlugin()
  of NetworkPluginName:
    plugin = initNetworkPlugin()
  of UptimePluginName:
    plugin = initUptimePlugin()
  else:
    result = UnknownServiceResponse
    return

  result = plugin.config()

proc receiveFromClient(server: Server, address: string, client: AsyncSocket) {.async.} =
  var buffer = newFutureVar[string]("munin_node.server.receiveFromClient")
  buffer.mget() = newStringOfCap(BufferSize)

  var response: string

  while server.listen and not client.isClosed():
    buffer.mget.setLen(0)
    buffer.clean()

    await client.recvLineInto(buffer)

    echo "Received line from client '", address, "': ", buffer.mget

    # can't simply use a `case` statement here as commands usually have a suffix such as `config df`
    if len(buffer.mget) == 0:
      break
    elif len(buffer.mget) >= 4 and buffer.mget[0..3] == "quit":
      break
    elif len(buffer.mget) >= 4 and buffer.mget[0..3] == "list":
      response = ProcessesPluginName & " " & MemoryPluginName & " " & NetworkPluginName & " " & UptimePluginName & " \L"
    elif len(buffer.mget) >= 5 and buffer.mget[0..4] == "nodes":
      # This version only supports one node
      response = server.hostname & "\L.\L"
    elif len(buffer.mget) >= 5 and buffer.mget[0..4] == "fetch":
      response = processFetchRequest(buffer.mget)
    elif len(buffer.mget) >= 6 and buffer.mget[0..5] == "config":
      response = processConfigRequest(buffer.mget)
    elif len(buffer.mget) >= 7 and buffer.mget[0..6] == "version":
      response = "munin node on " & server.hostname & " version: " & VersionString & "\L"
    else:
      response = UnknownCommandResponse

    await client.send(response)

proc processClient(server: Server, address: string, client: AsyncSocket) {.async.} =
  try:
    echo "Accepted client from address: ", address

    await client.send("# munin node at " & server.hostname & "\L")
    await server.receiveFromClient(address, client)
  finally:
    echo "Lost connection to client from address: ", address

    client.close()

proc run*(server: Server) {.async.} =
  ## Continuously accept incoming connections.
  while server.listen:
    let (address, client) = await server.sock.acceptAddr()

    asyncCheck server.processClient(address, client)
