@echo off
setlocal EnableDelayedExpansion

::set bcomp="C:\Program Files (x86)\Beyond Compare 4\BComp.com"

cmd.exe /c chcp 1252 >NUL

::set types = ("crc" "binary" "size")

if "%1" equ "" (
goto :usage
)

if "%2" equ "" (goto :usage)

set file1=%1
set file2=%2

if NOT EXIST %file1% ( 
echo %file1% does not exist
REM goto :usage
)

if NOT EXIST %file2% ( 
echo %file2% does not exist
REM goto :usage
)

if "%3" neq "" (
	set comptype=%3
	
	set "valid="
	for %%A in ("crc", "binary", "size") do (		
		if "!comptype!"==%%A (
			set "valid=1"
		)
	)
	
	if !valid! equ 1 (		
		bcomp /qc=!comptype! %file1% %file2%		
		set errorlevelpdf=!errorlevel!
		goto :eof
	) else (
		echo !comptype! is not a valid comparison type
		REM goto :usage
	)
) else (	
	bcomp /qc %file1% %file2%
	
	for %%B in (1, 2) do (
		if !errorlevel! equ %%B (
			set errorlevelpdf=1			
			exit /b !errorlevel!
			goto :eof
		)		
	)	
	goto :eof	
)


exit /b !errorlevel!

:usage
echo Usage: %0 filename1 filename2 comptype
echo comptype is optional. Acceptable comptype values: crc, binary, size
echo Returns 0=different 1=same , when comptype is not specified (defaulted to rules based comparision)
echo When comptype is specified below are the return codes
echo 0 Success
echo 1 Binary same
echo 2 Rules-based same
echo 11 Binary differences
echo 12 Similar
echo 13 Rules-based differences
echo 14 Conflicts detected
echo 100 Unknown error"
exit /b 404
goto :eof
 