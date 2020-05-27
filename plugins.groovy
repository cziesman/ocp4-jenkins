def pluginList = new ArrayList(Jenkins.instance.pluginManager.plugins)
pluginList.sort { it.getShortName() }.each{
  plugin ->
    println ("${plugin.getShortName()}:latest")
}
