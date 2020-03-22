import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jjson]
import jsffi, asyncjs, math, strutils
import sugar, macros, vstylemacros, xterm
import jslibs / xtermjs

var pty {.importjs.}: JsObject

var expanded = false
var lastCompletion: kstring = ""

proc onkeyupenter(ev: Event, target: VNode) =
  pty.writeln(target.text)
  target.text = ""
  expanded = false
  lastCompletion = ""

proc sleep(ms: int): Future[void] =
  result = newPromise(proc (resolve: proc()) = runLater(resolve, ms))

proc autocomplete(target: VNode, s: kstring) {.async, discardable.} =
  currentLine = ""
  if lastCompletion == s:
    pty.write(s & "\t\t")
  else:
    pty.write(s & "\t")
  await sleep(100)
  let backlen = ceil currentLine.len/2
  let backspaces = repeat('\b', int backlen)
  pty.write(backspaces)
  terminal.write(backspaces)
  target.setInputText(currentLine)
  lastCompletion = currentLine
  currentLine = ""
  expanded = true
  # pty.eraseLine()
  # eraseLine()

proc onkeydown(ev: Event, target: VNode) =
  let kbev = (KeyboardEvent)ev
  if kbev.keyCode == 9: # TAB
    kbev.preventDefault()
    # target.text = "text"
    target.autocomplete(target.text)
    # pty.write(target.text & "\t")

proc inputField*(): VNode =
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
    input(id = "commandInput", style = inputStyle, onkeydown = onkeydown,
        onkeyupenter = onkeyupenter)

