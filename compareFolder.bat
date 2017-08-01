@echo off
setlocal EnableDelayedExpansion

:: Dependencies
:: beyond compare should be installed and available (folder included in path)
:: java should be installed and available (folder included in path)
:: excel_cmp, 7z should be installed and available (folder included in path). Preferably in Dropbox\apps
:: foldernames should be fully qualified paths without trailing slashes example: E:\tests\out
:: CompareExcel should be in the same folder as this script ie %~dp0

cmd.exe /c chcp 1252 >NUL
set /a retval=0
if [%1] equ [] (goto :usage)
if [%2] equ [] (goto :usage)

REM set curDir=%CD%

::employed technique to convert relative path to a fully qualified path from https://stackoverflow.com/questions/6591544/how-can-i-convert-a-relative-path-to-a-fully-qualified-path-in-a-dos-batch-file
FOR /F "delims=" %%F IN ("%1") DO SET "folder1=%%~fF"
FOR /F "delims=" %%F IN ("%2") DO SET "folder2=%%~fF"

if NOT EXIST %folder1% ( 
	echo %folder1% does not exist
	set /a retval=404
	goto :usage
)

if NOT EXIST %folder2% ( 
	echo %folder2% does not exist
	set /a retval=404
	goto :usage
)

::extract all zip folders in both folders.
set "i=0"
for /R "%folder1%" %%f  in (*.zip) do (	
	echo "%%f"
	7z.exe e -y -o"%folder1%\%%~nf" "%%f"	
	set folderToDel[!i!]=%folder1%\%%~nf
	set /a i=!i!+1
)

for /R "%folder2%" %%f in (*.zip) do (
	echo "%%f"
	7z.exe e -y -o"%folder2%\%%~nf" "%%f"
	set folderToDel[!i!]=%folder2%\%%~nf
	set /a i=!i!+1
)

REM Compare logic starts here
set "ext="
set "finalResult=SUCCESS"
REM set "SpecialExt=YES"
ECHO.>out.csv

for /R "%folder1%" %%f in (*.*) do (	
	set "ext=%%~xf"	
	set "B=%%f"
	set "fileResult=UNINITIALIZEDorUNKNOWNEXT"
	set relPath=!B:%folder1%\=!
	REM echo Relative Path: !relPath!
	
	set "SpecialExt=NO"
	for %%P in (.pdf, .xls, .xlsx, .zip) do (
		if !ext! equ %%P (
			set "SpecialExt=YES"
		)
	)
	
	REM if !SpecialExt! equ YES (
		REM set "finalResult=FAIL"
		REM call :insert
	REM )
	
	if NOT EXIST !folder2!\!relpath! (
		set "fileResult=NOFILEonRIGHT"
		set "finalResult=FAIL"
		call :insert
	) else (
		if !SpecialExt! equ YES (
			if !ext! equ .pdf (
				REM echo in pdf
				REM call comparePDF %%f !folder2!\!relpath!
				call bcomp /qc %%f !folder2!\!relpath!
				REM echo pdf result !errorlevel!;		
				
				if  !errorlevel! equ 1 (
					set "fileResult=SUCCESS"
				) else (
					if !errorlevel! equ 2 (
						set "fileResult=SUCCESS"
					) else (
						set "fileResult=FAIL"
						set "finalResult=FAIL"
					)
				)	
				call :insert
			)
			
			REM END  of pdf if
			
			for %%C in (.xls, .xlsx) do (
				if !ext! equ %%C (
					REM echo In Excel
					call %~dp0compareExcel "%%f" "!folder2!\!relpath!"
					
					if !errorlevel! equ 0 (
						set "fileResult=SUCCESS"
					) else (
						if !errorlevel! equ 1 (
							set "fileResult=FAIL"
						) else (
							set "fileResult=ERROR"
						)
						set "finalResult=FAIL"	
					)				
					call :insert
				)
			)
			REM END  of XLS if	
			
			
			if !ext! equ .zip (
				set "fileResult=IGNOREDzIP"	
				call :insert
			)
		) else (
		
			REM for every other extension do beyond comapre binary compare
			call bcomp /qc=binary %%f !folder2!\!relpath!
			if !errorlevel! equ 1 (
				set "fileResult=SUCCESS"
			) else (
				set "fileResult=FAIL"
				set "finalResult=FAIL"
			)		
			call :insert
		)
		
		
		REM for %%D in (.csv, .txt, .USR) do (
			REM if !ext! equ %%D (
				REM call bcomp /qc=binary %%f !folder2!\!relpath!
				REM if !errorlevel! equ 1 (
					REM set "fileResult=SUCCESS"
				REM ) else (
					REM set "fileResult=FAIL"
					REM set "finalResult=FAIL"
				REM )
				REM call :insert
			REM )
		REM )
	)
	REM end of else condition
	
	REM echo !fileResult!, %%f, !folder2!\!relpath! >> out.csv	
)
REM end of fodler1 for loop

for /R "%folder2%" %%m in (*.*) do (	
	set "Q=%%m"	
	set relPath=!Q:%folder2%\=!
	
	if NOT EXIST !folder1!\!relpath! (
		set "fileResult=NewFileonRight"
		set "finalResult=FAIL"
		echo !fileResult!, !folder1!\!relpath!, %%m >> out.csv
	)	
)

echo Deleting unzipped Folders....
set /a iComp=!i!-1
for /l %%n in (0,1,!iComp!) do (
	echo !folderToDel[%%n]!
	rmdir /S /Q "!folderToDel[%%n]!"
)

echo FINAL RESULT: **********!finalResult!*****************
echo Detailed results for each file are stored in out.csv
echo finalResult=!finalResult!
if !finalResult! equ FAIL (
  exit /b 1
) else (
  exit /b 0
)
goto :eof


:insert
echo !fileResult!, !B!, !folder2!\!relpath! >> out.csv
exit /b


:usage
echo Usage: %0 foldername1 foldername2
echo returns 0 for success, 1 for failure
::echo retval=!retval!
exit /b !retval!
goto :eof