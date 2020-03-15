import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, jjson]
import jsffi
import sugar
import jslibs / xtermjs

const term_id = kstring"terminal"
var terminal{.exportc.}: JsObject
var pty {.importjs.}: JsObject


proc xterm(): VNode =
  let style = style(
      (StyleAttr.width, kstring"100%"),
      (StyleAttr.height, kstring"95vh"),
  )
  result = buildHtml:
    tdiv(id = term_id, style = style)

proc inputField(): VNode =
  let style = style(
    (StyleAttr.width, kstring"100%"),
    (StyleAttr.height, kstring"5vh"),
    (StyleAttr.borderRadius, kstring"0"),
    (StyleAttr.border, kstring"0"),
    (StyleAttr.backgroundColor, kstring"black"),
    (StyleAttr.color, kstring"white")
  )
  result = buildHtml:
    input(style = style):
      proc onkeyupenter(ev: Event, target: VNode) =
        pty.write(target.text)
        target.text = ""

proc postRender() =
  if terminal == nil:
    let thediv = getElementById(term_id)
    terminal = newTerminal()
    terminal.open(thediv)

proc createDom(): VNode =
  result = buildHtml(tdiv):
    xterm()
    inputField()

setRenderer createDom, "ROOT", postRender
setForeignNodeId term_id
