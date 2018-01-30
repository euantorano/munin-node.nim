## Server to accept incoming connections from a munin master.

import ./utils, ./plugin, ./plugins/processes, ./plugins/memory, ./plugins/network, ./plugins/uptime

import asyncdispatch, asyncnet, nativesockets, tables, logging

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

var
  plugins {.threadvar.}: TableRef[string, Plugin]
  pluginList {.threadvar.}: string

proc initServer*(port: uint16 = DefaultListenAddress, hostname: string = ""): Server =
  ## Intiailise a new server and bind it, ready to accept incoming connections.
  result = Server(
    sock: newAsyncSocket(),
    listen: true,
    hostname: if len(hostname) == 0: getHostname() else: hostname
  )

  if isNil(plugins):
    # TODO: This should happen in the `main` proc in `../munin_node` and be based upon configuration
    plugins = newTable[string, Plugin]()
    plugins.add(MemoryPluginName, newMemoryPlugin())
    plugins.add(NetworkPluginName, newNetworkPlugin())
    plugins.add(ProcessesPluginName, newProcessesPlugin())
    plugins.add(UptimePluginName, newUptimePlugin())

  result.sock.setSockOpt(OptReuseAddr, true)
  result.sock.bindAddr(Port(port))
  result.sock.listen()

  notice("Server started listening on port ", port, " with hostname: ", result.hostname)

proc listPlugins(): string {.inline.} =
  if isNil(pluginList):
    pluginList = ""

    for pluginName in plugins.keys():
      pluginList.add(pluginName & " ")

      pluginList.add("\L")

  result = pluginList

proc processFetchRequest(request: string): string =
  let startIndex = if len(request) > 6 and request[5] == ' ': 6 else: 5
  let plugin = request[startIndex..^1]

  if plugin in plugins:
    try:
      result = plugins[plugin].values()
    except:
      warn("Error handling fetch request for plugin '", plugin , "': ", getCurrentExceptionMsg())

      result = UnknownErrorResponse
  else:
    result = UnknownServiceResponse

proc processConfigRequest(request: string): string =
  let startIndex = if len(request) > 7 and request[6] == ' ': 7 else: 6
  let plugin = request[startIndex..^1]

  if plugin in plugins:
    try:
      result = plugins[plugin].config()
    except:
      warn("Error handling config request for plugin '", plugin , ": ", getCurrentExceptionMsg())

      result = UnknownErrorResponse
  else:
    result = UnknownServiceResponse

proc receiveFromClient(server: Server, address: string, client: AsyncSocket) {.async.} =
  var buffer = newFutureVar[string]("munin_node.server.receiveFromClient")
  buffer.mget() = newStringOfCap(BufferSize)

  var response: string

  while server.listen and not client.isClosed():
    buffer.mget.setLen(0)
    buffer.clean()

    await client.recvLineInto(buffer)

    # can't simply use a `case` statement here as commands usually have a suffix such as `config df`
    if len(buffer.mget) == 0:
      break
    elif len(buffer.mget) >= 4 and buffer.mget[0..3] == "quit":
      break
    elif len(buffer.mget) >= 4 and buffer.mget[0..3] == "list":
      response = listPlugins()
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
      warn("Received unknown command from client '", address, "': ", buffer.mget)
      response = UnknownCommandResponse

    await client.send(response)

proc processClient(server: Server, address: string, client: AsyncSocket) {.async.} =
  try:
    debug("Accepted incoming connection from address: ", address)

    await client.send("# munin node at " & server.hostname & "\L")
    await server.receiveFromClient(address, client)
  finally:
    client.close()

proc run*(server: Server) {.async.} =
  ## Continuously accept incoming connections.
  while server.listen:
    let (address, client) = await server.sock.acceptAddr()

    asyncCheck server.processClient(address, client)
