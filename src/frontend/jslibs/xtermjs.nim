import jsffi

const fitAddonCode = staticRead("FitAddon.js")
{.emit: fitAddonCode.}

proc newTerminal*(): JsObject {.importjs: "new Terminal()", nodecl.}
proc newFitAddon*(): JsObject {.importjs: "new FitAddon()", nodecl.}


proc open*(term: JsObject, parent: JsObject): void {.importjs: "#.open(@)".}

proc write*(term: JsObject, data: string, callback: proc(): void): void {.
    importjs: "#.write(@)".}

proc write*(term: JsObject, data: seq[byte], callback: proc(): void): void {.
    importjs: "#.write(@)".}

proc loadAddon*(term: JsObject, addon: auto): void {.
    importjs: "#.loadAddon(@)".}
