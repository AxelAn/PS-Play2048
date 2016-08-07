@ECHO OFF
PowerShell.exe -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -WindowStyle Hidden -Command "& '%~d0%~p0%~n0.ps1'" %*
EXIT /B %errorlevel%