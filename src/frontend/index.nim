import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, jjson]
import jsffi
import sugar
import jslibs / xtermjs

const term_id = kstring"terminal"
var terminal{.exportc.}: JsObject
var fitaddon{.exportc.}: JsObject
var pty {.importjs.}: JsObject


proc xterm(): VNode =
  result = buildHtml:
    tdiv(id = term_id)

proc inputField(): VNode =
  result = buildHtml:
    input():
      proc onkeyupenter(ev: Event, target: VNode) =
        pty.write(target.text)
        target.text = ""

proc postRender() =
  if terminal == nil:
    let thediv = getElementById(term_id)
    terminal = newTerminal()
    fitaddon = newFitAddon()
    terminal.loadAddon(fitaddon)
    terminal.open(thediv)
    fitaddon.fit()

proc createDom(): VNode =
  result = buildHtml(tdiv):
    xterm()
    inputField()

setRenderer createDom, "ROOT", postRender
setForeignNodeId term_id
