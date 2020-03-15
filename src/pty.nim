# forkpty reimplementation
import os, posix, asyncdispatch, threadpool, streams, sugar

proc asyncReadline*(f: File): Future[string] =
  let event = newAsyncEvent()
  let future = newFuture[string]("asyncReadline")
  proc readlineBackground(event: AsyncEvent, f: File): string =
    result = f.readline()
    event.trigger()
  let flowVar = spawn readlineBackground(event, f)
  proc callback(fd: AsyncFD): bool =
    future.complete(^flowVar)
    true
  addEvent(event, callback)
  return future

proc asyncReadChar*(f: File): Future[char] =
  let event = newAsyncEvent()
  let future = newFuture[char]("asyncReadline")
  proc readlineBackground(event: AsyncEvent, f: File): char =
    result = f.readChar()
    event.trigger()
  let flowVar = spawn readlineBackground(event, f)
  proc callback(fd: AsyncFD): bool =
    future.complete(^flowVar)
    true
  addEvent(event, callback)
  return future

type
  Pty* = object
    master*: File
    windowSize*: WindowSize
    onData*: AsyncEvent
  WindowSize = object
    rows*: cushort    # rows, in characters
    columns*: cushort # columns, in characters
    width*: cushort   # horizontal size, pixels
    height*: cushort  # vertical size, pixels


proc checkErrorCode*(err: cint or int) =
  if err < 0:
    raiseOSError(osLastError())

proc posix_openpt(flags: cint): FileHandle {.importc.}
proc unlockpt(fd: cint): cint {.importc.}
proc grantpt(fd: cint): cint {.importc.}
proc ptsname(fd: cint): cstring {.importc.}


proc setWindowSize(pty: Pty) =
  const TIOCSWINSZ = 21524
  var ptyForAddr = pty.windowSize
  checkErrorCode ioctl(pty.master.getOsFileHandle(), TIOCSWINSZ,
      addr ptyForAddr)

proc openMasterFile(): File =
  let masterFileHandle = posix_openpt(O_RDWR)
  checkErrorCode masterFileHandle
  checkErrorCode grantpt(masterFileHandle)
  checkErrorCode unlockpt(masterFileHandle)

  var masterFile: File
  if open(masterFile, masterFileHandle):
    return masterFile
  else:
    raise newException(OSError, "Could not open masterfile")

proc onData*(pty: Pty, cb: proc(c: char)) =
  proc readCharBackground(pty: Pty, cb: proc(c: char)) =
    while true:
      cb pty.master.readChar()
  spawn readCharBackground(pty, cb)


proc newPty*(process: string, rows: uint16 = 20, columns: uint16 = 20,
    width: uint16 = 200, height: uint16 = 200): Pty =
  let winSize = WindowSize(rows: rows, columns: columns, width: width,
      height: height)
  result = Pty(windowSize: winSize, master: openMasterFile(),
      onData: newAsyncEvent())

  let masterFileHandle = result.master.getOsFileHandle()
  result.setWindowSize()
  var slave = ptsname(masterFileHandle)
  checkErrorCode slave.len
  var pid: Pid = fork()
  checkErrorCode pid
  if pid == 0:
    # Running inside slave process
    checkErrorCode close(masterFileHandle) # Close the master file
    checkErrorCode setsid() # Set as leader of new group session
    var slaveFile: FileHandle = open(slave, O_RDWR)         # Create slave file
    checkErrorCode slaveFile
    # Connect stdin, stout and stderr to slavefile
    checkErrorCode dup2(slaveFile, 0)
    checkErrorCode dup2(slaveFile, 1)
    checkErrorCode dup2(slaveFile, 2)
    # Replace slave process with requested process. This should never return
    checkErrorCode execl(cstring(process), cstring(process), nil)
    quit(1)

when isMainModule:
  proc readMaster(master: File) {.async.} =
    var inputFuture: Future[char] = master.asyncReadChar()
    while true:
      let input = await inputFuture
      stdout.write input
      inputFuture = master.asyncReadChar()


  proc myTask(master: File) {.async.} =
    var inputFuture: Future[string] = stdin.asyncReadline()
    while true:
      let input = await inputFuture
      let msg = cstring(input & '\n')
      checkErrorCode write(master.getOsFileHandle(), msg, msg.len)
      inputFuture = stdin.asyncReadline()


  let pty = newPty("/bin/sh")
  sleep(100)
  # asyncCheck readMaster(pty.master)

  onData(pty, (c: char) => stdout.write c)
  asyncCheck myTask(pty.master)
  runForever()
