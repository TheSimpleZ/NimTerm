import jsffi


proc newTerminal*(): JsObject {.importjs: "new Terminal()", nodecl.}


proc open*(term: JsObject, parent: JsObject): void {.importjs: "#.open(@)".}

proc write*(term: JsObject, data: string, callback: proc(): void): void {.
    importjs: "#.write(@)".}

proc write*(term: JsObject, data: seq[byte], callback: proc(): void): void {.
    importjs: "#.write(@)".}
