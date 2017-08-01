
@echo off
::setlocal EnableDelayedExpansion

REM --Requires Java 1.6 or higher.
REM --Assumes Java is added to PATH (to check open a cmd and run java -version)

cmd.exe /c chcp 1252 >NUL

if [%1] equ [] (
goto :usage
)

if [%2] equ [] (goto :usage)

set file1=%1
set file2=%2

if NOT EXIST %file1% ( 
	echo %file1% does not exist
	goto :usage
)

if NOT EXIST %file2% ( 
	echo %file2% does not exist
	goto :usage
)

set compareCmd=excel_cmp %file1% %file2%

for /F "tokens=* USEBACKQ" %%F IN (`%compareCmd%`) do (
	set result=%%F
)

REM echo Result: %result%
REM set passFormat=Excel files %file1% and %file2% match
REM echo Passformat:
REM echo %passFormat%

REM echo %result% findstr /C:"%passFormat%"

echo.%result%| findstr /R "match$" 1>nul
REM echo %errorlevel%
if errorlevel 1 (
  echo.All worksheets do not match
) else (
  echo.All worksheets match
)
exit /b %errorlevel%
goto :eof

:usage
echo Usage: %0 filename1 filename2
exit /b 404
goto :eof
