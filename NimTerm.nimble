# Package

version       = "0.1.0"
author        = "Zrean Tofiq"
description   = "A serial port terminal"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["NimTerm"]



# Dependencies

requires "nim >= 1.0.6"
requires "webview"

task clean, "Remove all binaries":
  rmDir("./bin")

task buildgui, "Build the GUI":
  rmDir("./bin")