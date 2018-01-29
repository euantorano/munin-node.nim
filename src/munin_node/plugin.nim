## A plugin is a core part of the munin node. Plugins are responsible for reporting system statistics and explaining the graph configuration.

type
  GetConfigFunction* = proc(plugin: Plugin): string {.nimcall.}
    ## A function to get the plugin configuration. The plugin configuration explains the graph indices, title, category, etc.

  GetValuesFunction* = proc(plugin: Plugin): string {.nimcall.}
    ## A function to get the plugin's values.

  Plugin* = object
    name*: string
    configFunction: GetConfigFunction
    valuesFunction: GetValuesFunction

proc initPlugin*(name: string, configFunction: GetConfigFunction, valuesFunction: GetValuesFunction): Plugin =
  result = Plugin(
    name: name,
    configFunction: configFunction,
    valuesFunction: valuesFunction
  )

proc config*(plugin: Plugin): string =
  ## Get the plugin's configuration. The plugin configuration explains the graph indices, title, category, etc.
  result = plugin.configFunction(plugin)

proc values*(plugin: Plugin): string =
  ## Get the plugin's values as a string.
  result = plugin.valuesFunction(plugin)

# TODO: A macro that builds a table of plugins for easy lookup and access