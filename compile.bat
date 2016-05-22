
::nim c --app:gui --passL:user32.lib -r loopback.nim
nim c loopback.nim
::nim c wintest.nim

IF ERRORLEVEL 1 GOTO ERROR
loopback.exe
::wintest.exe
::EXIT

:ERROR
