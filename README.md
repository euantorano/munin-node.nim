# munin-node

A munin node implemented in Nim.

At the moment, this is currently aimed at Windows based machines and has had very little testing. The aim is to cover other platforms further down the road.

## Plugins

The idea behind munin is that it relies on plugins to collect statistics and information about a given host. This Nim implementation is no different.

There isn't currently a way to dynamically configure or load plugins, and all current plugins are hard-coded with no configuration. The plan is to be able to load plugins as dynamic libraries, and to support running scripts via a shell as plugins.

The currently implemented plugins are:

- [ ] Memory Usage
    - [X] Windows
    - [ ] Other platforms
- [ ] Network Traffic (packets per second)
    - [X] Windows
    - [ ] Other platforms
- [ ] Process and Thread counts
    - [X] Windows
    - [ ] Other platforms
- [ ] System uptime
    - [X] Windows (though there is a known bug with Windows 8 or newer relating to `fast boot` causing incorrect values)
    - [ ] Other platforms
- [ ] CPU Usage
- [ ] Temperate Data
- [ ] Fan Speed
- [ ] Disk Usage
