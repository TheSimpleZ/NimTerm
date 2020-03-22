import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jjson]
import jsffi
import sugar, macros, vstylemacros, xterm, inputfield
import jslibs / xtermjs


var runOnce = false
proc postRender() =
  if not runOnce:
    initXterm()
    runOnce = true

proc createDom(): VNode =
  result = buildHtml(tdiv):
    xterm()
    inputField()

setRenderer createDom, "ROOT", postRender
setForeignNodeId term_id
