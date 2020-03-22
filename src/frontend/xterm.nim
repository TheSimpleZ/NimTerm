
import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jjson]
import jsffi, sugar, asyncjs, math
import sugar, macros, vstylemacros, sequtils, strutils
import jslibs / xtermjs
import experimental/diff

const term_id* = kstring"terminal"
var
  terminal*{.exportc.}: JsObject
  fitaddon*{.exportc.}: JsObject
  pty {.importjs.}: JsObject

proc onBodyResize() {.exportc.} =
  let newSize = fitaddon.fit()
  if cast[bool](pty):
    pty.setRows(newSize.rows)
    pty.setColumns(newSize.cols)

var currentLine*: kstring = ""
var outputEnabled = true
proc xtermWrite(bytes: openarray[byte]) {.exportc.} =
  if outputEnabled:
    terminal.write(bytes)
  currentLine.add bytes.mapIt($char(it)).join()
  if '\n' in $currentLine:
    currentLine = splitLines($currentLine)[^1]


proc eraseLine*() =
  terminal.write toSeq("\e[2K".items).mapIt(byte(it))

proc initXterm*() =
  terminal = newTerminal()
  fitaddon = newFitAddon()
  terminal.loadAddon(fitaddon)
  terminal.open getElementById(term_id)

proc xterm*(): VNode =
  let style = buildStyle:
    width: "100%"
    flexGrow: "1"
    backgroundColor: "black"

  result = buildHtml:
    tdiv(id = term_id, style = style)
