@ECHO OFF

REM ======================================================================
REM This batch file will remove competing AV products and install webroot.
REM ======================================================================

REM This like checks to for a registry key that Webroot installs.
REM ======================================================================
reg query HKLM\Software\WOW6432Node\WRData /v InstallTime

REM If the key exists, exit.
REM ======================================================================
IF %ERRORLEVEL% == 0 GOTO :EOF

REM Copy files from a fileshare to temp.
REM ======================================================================
xcopy /S /i /y "\\[REDACTED]\deployment\SEPprep" "%temp%\SEPprep"

REM change directory to temp.
REM ======================================================================
cd %temp%\SEPprep

REM cheap trick to see if x64 or not and run the appropriate file.
REM ======================================================================
IF EXIST "%PROGRAMFILES(X86)%" (
	%temp%\SEPprep\SEPprep64.exe
	) ELSE (
	%temp%\SEPprep\SEPprep.exe
	)

REM install webroot once SEPPrep is complete.
REM ======================================================================
wsasme.exe /key=[LICENSE KEY] /silent