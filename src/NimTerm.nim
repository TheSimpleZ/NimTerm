import webview
import gui
import os, asyncdispatch, threadpool
import pty, posix, sequtils, marshal

var chan: Channel[byte]
let wv = newWebView(title = "NimTerm", url = dataUrl,
width = 1000,
height = 700, resizable = true, debug = true, cb = nil)


let myPty = newPty("/bin/bash")

chan.open()

# Write data to terminal as bytes
onData(myPty, proc (c: char) = chan.send(byte(c)))


wv.bindProcs"pty":
    proc write(s: string) =
        myPty.write(s)
    proc writeln(s: string) =
        myPty.writeln(s)
    proc backspace(repeat: int) =
        myPty.backspace(repeat)
    proc setRows(rows: uint16) =
        myPty.windowSize.rows = rows
        myPty.applyNewWindowSize()
    proc setColumns(cols: uint16) =
        myPty.windowSize.columns = cols
        myPty.applyNewWindowSize()

discard wv.eval("onBodyResize();")

while wv.loop(0) == 0:
    var tried = chan.tryRecv()
    var totalMsg: seq[byte]
    while tried.dataAvailable and totalMsg.len < 4000:
        totalMsg = totalMsg & tried.msg
        tried = chan.tryRecv()

    if totalMsg.len > 0:
        discard wv.eval("xtermWrite(" & $$totalMsg & ");")


