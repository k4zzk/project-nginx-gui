fs      = require 'fs'
path    = require 'path'
os      = require 'os'
exec    = require('child_process').exec
Promise = require 'promise'
Error   = require './Error'
PlatformUndefinedError = Error.PlatformUndefinedError
ExecuteError           = Error.ExecuteError
CommandNotFoundError   = Error.CommandNotFoundError

###
  command の絶対パスを取得するためのクラス
###
class Command

  constructor: ()->
    if _getCaller().func == "Command.getInstance"
      PATH_SEPARATOR = _getSeparator()
      envPaths = _getEnvPathList(PATH_SEPARATOR).reverse()
      @commandsSet = _getCommandsSet(envPaths, PATH_SEPARATOR)
    else
      throw new Error("Should get an instance from `getInstance` method!")

  @getInstance = ->
    @instance = new Settings() if !@instance?
    return @instance

  _getSeparator = ->
    platform  = os.type()
    isLinux   = platform is "Linux"
    isDarwin  = platform is "Darwin"
    isWindows = platform is "Windows_NT"
    if isLinux or isDarwin
      ":"
    else if isWindows
      ";"
    else
      throw new PlatformUndefinedError()

  _getEnvPathList = (path_separator)->
    env_path_str = process.env.PATH
    return env_path_str.split(path_separator)

  _isPathExist = (path)->
    try
      fs.accessSync(path, fs.R_OK)
      return true
    catch error
      return false

  _getFileNames = (path)->
    return fs.readdirSync(path)

  _getCommandsSet = (env_paths)->
    commands = {}
    for env_path in env_paths
      if _isPathExist(env_path)
        command_names = _getFileNames(env_path)
        for command_name in command_names
          command_path = path.join(env_path, command_name)
          commands[command_name] = command_path

    return commands

  ###
     @method getCommandPath(cmd)
       cmd: string コマンドの名前
     @return string コマンドに対するフルパス
  ###
  getCommandPath: (cmd)->
    return @commandsSet[cmd]

  run: (command, callback)->
    cmds = command.split(/ +?/)
    cmd_path = @getCommandPath(cmds[0])
    cmd_args = cmds.slice(1).join(" ")
    command = "#{cmd_path} #{cmd_args}"
    # console.log("#{cmd_path} #{cmd_args}")
    throw new CommandNotFoundError() if !(cmd_path && cmd_path.trim())
    promise = new Promise (resolve, reject)->
      child = exec command, (error, stdout, stderr)->
        if error?
          reject(stderr)
          throw new ExecuteError()
        resolve(stdout)
        # console.log('stdout: ' + stdout);
        # console.log('stderr: ' + stderr);
    promise.nodeify(callback)

  # from http://qiita.com/pirosikick/items/04e099476d46c6389a1b
  _getCaller = (stackIndex) ->
    callerInfo = {}
    saveLimit = Error.stackTraceLimit
    savePrepare = Error.prepareStackTrace
    stackIndex = stackIndex - 0 or 1
    Error.stackTraceLimit = stackIndex + 1
    Error.captureStackTrace this, _getCaller

    Error.prepareStackTrace = (_, stack) ->
      caller = stack[stackIndex]
      callerInfo.file = caller.getFileName()
      callerInfo.line = caller.getLineNumber()
      func = caller.getFunctionName()
      if func
        callerInfo.func = func
      return

    @stack
    Error.stackTraceLimit = saveLimit
    Error.prepareStackTrace = savePrepare
    callerInfo
    # ---
    # generated by js2coffee 2.1.0

module.exports = Command


# command = new Command()
# command.run "nginx", ()->
#   console.log("done")
