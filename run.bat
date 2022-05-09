@echo off
set executable=zig-out\bin\typeroo.exe
if exist %executable% (del %executable%)
call timecmd zig build
if exist %executable% (call %executable%)
goto :done

:done
