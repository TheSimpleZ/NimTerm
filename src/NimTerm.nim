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

# Write data to terminal as bytes
onData(myPty, proc (c: char) = chan.send("terminal.write(new Uint8Array([" &
        $byte(c) & "]));"))


wv.bindProcs"pty":
    proc write(s: string) =
        myPty.write(s)


while wv.loop(1) == 0:
    let tried = chan.tryRecv()
    if tried.dataAvailable:
        discard wv.eval(tried.msg) # "Another message"


