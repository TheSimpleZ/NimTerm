import macros

macro buildStyle*(stmtList: untyped): untyped =
  stmtList.expectKind nnkStmtList

  result = newCall("style")
  for call in stmtList:
    let attrName = call[0]
    let attrVal = call[1][0]
    attrName.expectKind(nnkIdent)
    attrVal.expectKind(nnkStrLit)
    result.add quote do:
      (StyleAttr.`attrName`, cstring `attrVal`)


when isMainModule:
  dumptree:
    width: "100%"
    backgrouColor: "#111"
