import strformat

const staticFilesFolder = "frontend"
const entryfile = "index"

static:
    # Build the gui
    const (output, exitCode) = gorgeEx(&"nim js {staticFilesFolder}/{entryfile}.nim")

    if exitCode != 0:
        echo output
        quit(QuitFailure)

# Pack it into one html file in memory
const js = staticRead(&"{staticFilesFolder}/{entryfile}.js")
const css = staticRead(&"{staticFilesFolder}/{entryfile}.css")

const dataUrl* = &"""data:text/html,
<head>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm@4/css/xterm.min.css">
<script src="https://cdn.jsdelivr.net/npm/xterm@4/lib/xterm.min.js"></script>
<style>
    {css}
</style>
</head>
<body id="body">
    <div id="ROOT"">
    </div>
    <script>
        {js}
    </script> 
</body>"""
