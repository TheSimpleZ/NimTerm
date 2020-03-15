import webview
import gui
import os, asyncdispatch, threadpool
import pty, posix

var chan: Channel[string]
let wv = newWebView(title = "NimTerm", url = dataUrl,
width = 1000,
height = 700, resizable = true, debug = true, cb = nil)


let myPty = newPty("/bin/sh")

chan.open()

onData(myPty, proc (c: char) = chan.send("terminal.write(new Uint8Array([" &
        $byte(c) & "]));"))

# var bgThread: Thread[Webview]
# proc bg (wvv: Webview) {.thread.} =
#     chan.send("terminal.write('Hello');")

# createThread bgThread, bg, wv


wv.bindProcs"pty":
    proc write(s: string) =
        let msg = cstring(s & '\n')
        checkErrorCode write(myPty.master.getOsFileHandle(), msg, msg.len)




while wv.loop(1) == 0:
    let tried = chan.tryRecv()
    if tried.dataAvailable:
        discard wv.eval(tried.msg) # "Another message"


