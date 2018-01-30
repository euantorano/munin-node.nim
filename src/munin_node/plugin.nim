## A plugin is a core part of the munin node. Plugins are responsible for reporting system statistics and explaining the graph configuration.

type
  GetConfigFunction* = proc(plugin: Plugin): string {.nimcall, tags: [], gcsafe.}
    ## A function to get the plugin configuration. The plugin configuration explains the graph indices, title, category, etc.

  GetValuesFunction* = proc(plugin: Plugin): string {.nimcall, tags: [], gcsafe.}
    ## A function to get the plugin's values.

  Plugin* = ref PluginObj
    ## The base plugin type that other plugins should extend.

  PluginObj* = object of RootObj
    ## The base plugin type that other plugins should extend.
    name*: string
      ## The name of the plugin.
    configFunction*: GetConfigFunction
      ## The config function for the plugin, called by `plugin.config()`. Note that this should not be accessed directly.
    valuesFunction*: GetValuesFunction
      ## The values function for the plugin, called by `plugin.values()`. Note that this should not be accessed directly.

  NoConfigFunctionError* = object of Exception
    ## Error raised when a plugin has no defined config function.

  NoValuesFunctionError* = object of Exception
    ## Error raised when a plugin has no defined values function.

proc config*(plugin: Plugin): string =
  ## Get the plugin's configuration. The plugin configuration explains the graph indices, title, category, etc.
  if not isNil(plugin.configFunction):
    result = plugin.configFunction(plugin)
  else:
    raise newException(NoConfigFunctionError, "Plugin '" & plugin.name & "' has no config function")

proc values*(plugin: Plugin): string =
  ## Get the plugin's values as a string.
  if not isNil(plugin.valuesFunction):
    result = plugin.valuesFunction(plugin)
  else:
    raise newException(NoValuesFunctionError, "Plugin '" & plugin.name & "' has no values function")
