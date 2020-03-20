import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jjson]
import jsffi
import sugar, macros
import jslibs / xtermjs

const term_id = kstring"terminal"
var terminal{.exportc.}: JsObject
var fitaddon{.exportc.}: JsObject
var pty {.importjs.}: JsObject

proc onBodyResize() {.exportc.} =
  let newSize = fitaddon.fit()
  if cast[bool](pty):
    pty.setRows(newSize.rows)
    pty.setColumns(newSize.cols)


macro buildStyle(stmtList: untyped): untyped =
  stmtList.expectKind nnkStmtList

  result = newCall("style")
  result.add
  for call in stmtList:
    let attrName = call[0]
    let attrVal = call[1][0]
    result.add quote do:
      (StyleAttr.`attrName`, cstring `attrVal`)

proc xterm(): VNode =
  let style = buildStyle:
    width: "100%"
    flexGrow: "1"
    backgroundColor: "black"

  result = buildHtml:
    tdiv(id = term_id, style = style)

proc inputField(): VNode =
  let wrapperStyle = buildStyle:
    height: "30px"
    backgroundColor: "#111"
    display: "flex"
    flexDirection: "row"

  let inputStyle = buildStyle:
    borderRadius: "0"
    border: "0"
    color: "white"
    background: "transparent"
    height: "100%"
    flex: "1"
    marginLeft: "calc(2vh + 5px)"

  result = buildHtml(tdiv(style = wrapperStyle)):
    label(`for` = "commandInput", class = "arrow_box"):
      bold text "/bash"
    input(id = "commandInput", style = inputStyle):
      proc onkeyupenter(ev: Event, target: VNode) =
        pty.writeln(target.text)
        target.text = ""
      proc onkeydown(ev: Event, target: VNode) =
        let kbev = (KeyboardEvent)ev
        if kbev.keyCode == 9: # TAB
          kbev.preventDefault()
          pty.write(target.text & "\t")


proc postRender() =
  if terminal == nil:
    let thediv = getElementById(term_id)
    terminal = newTerminal()
    fitaddon = newFitAddon()
    terminal.loadAddon(fitaddon)
    terminal.open(thediv)

proc createDom(): VNode =
  result = buildHtml(tdiv):
    xterm()
    inputField()

setRenderer createDom, "ROOT", postRender
setForeignNodeId term_id
