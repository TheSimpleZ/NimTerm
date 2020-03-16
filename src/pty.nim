# forkpty reimplementation
import os, posix, asyncdispatch, threadpool, sugar

type
  Pty* = object
    master: File
    windowSize*: WindowSize
  WindowSize = object
    rows*: cushort    # rows, in characters
    columns*: cushort # columns, in characters
    width*: cushort   # horizontal size, pixels
    height*: cushort  # vertical size, pixels


proc checkErrorCode(err: cint or int) =
  if err < 0:
    raiseOSError(osLastError())

proc posix_openpt(flags: cint): FileHandle {.importc.}
proc unlockpt(fd: cint): cint {.importc.}
proc grantpt(fd: cint): cint {.importc.}
proc ptsname(fd: cint): cstring {.importc.}


proc applyNewWindowSize*(pty: Pty) =
  const TIOCSWINSZ = 21524
  var ptyForAddr = pty.windowSize
  checkErrorCode ioctl(pty.master.getOsFileHandle(), TIOCSWINSZ,
      addr ptyForAddr)

proc onData*(pty: Pty, cb: proc(c: char)) =
  proc readCharBackground(pty: Pty, cb: proc(c: char)) =
    while true:
      cb pty.master.readChar()
  spawn readCharBackground(pty, cb)

proc write*(pty: Pty, s: string) =
  let msg = cstring(s & '\n')
  checkErrorCode write(pty.master.getOsFileHandle(), msg, msg.len)

proc openMasterFile(): File =
  # Standard unix 98 pty
  let masterFileHandle = posix_openpt(O_RDWR)
  checkErrorCode masterFileHandle
  checkErrorCode grantpt(masterFileHandle)
  checkErrorCode unlockpt(masterFileHandle)

  var masterFile: File
  if open(masterFile, masterFileHandle):
    return masterFile
  else:
    raise newException(OSError, "Could not open masterfile")


proc newPty*(process: string, rows: uint16 = 20, columns: uint16 = 20,
    width: uint16 = 200, height: uint16 = 200): Pty =
  let winSize = WindowSize(rows: rows, columns: columns, width: width,
      height: height)
  # Open master file
  result = Pty(windowSize: winSize, master: openMasterFile())
  result.applyNewWindowSize() # Apply initial window size
  let masterFileHandle = result.master.getOsFileHandle()
  var slave = ptsname(masterFileHandle) # Get slave file name
  var pid: Pid = fork() # Fork and run slave process
  checkErrorCode pid
  if pid == 0:
    # Running inside slave process
    checkErrorCode close(masterFileHandle) # Close the master file
    checkErrorCode setsid() # Set as leader of new group session
    checkErrorCode slave.len
    var slaveFile: FileHandle = open(slave, O_RDWR)         # Create slave file
    checkErrorCode slaveFile
    # Connect stdin, stout and stderr to slavefile
    checkErrorCode dup2(slaveFile, 0)
    checkErrorCode dup2(slaveFile, 1)
    checkErrorCode dup2(slaveFile, 2)
    # Replace slave process with requested process. This should never return
    checkErrorCode execl(process, process, nil)
    quit(1)

when isMainModule:
  # Helper function which allows us to raed lines from a file in an async manner.
  proc asyncReadline(f: File): Future[string] =
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

  proc stdinToMaster(master: File) {.async.} =
    var inputFuture: Future[string] = stdin.asyncReadline()
    while true:
      let input = await inputFuture
      let msg = cstring(input & '\n')
      checkErrorCode write(master.getOsFileHandle(), msg, msg.len)
      inputFuture = stdin.asyncReadline()


  let pty = newPty("/bin/sh")
  sleep(100)

  onData(pty, (c: char) => stdout.write c)
  asyncCheck stdinToMaster(pty.master)
  runForever()
