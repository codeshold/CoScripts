@ECHO off

TITLE VB homeworks batching script

SET VBEXE="C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.exe"
SET RAREXE="C:\Program Files\2345Soft\HaoZip\HaoZipC.exe"
SET RAR_RESULT=rar_result.txt
SET SLN_RESULT=sln_result.txt
SET COUNT=10

ECHO=  
ECHO Current Directory: %CD%
ECHO= 
CHOICE /C 12 /N /M "Continue?(Enter 1) ; Exit?(Enter 2)"
IF ERRORLEVEL 2 EXIT

ECHO=   
ECHO Decompressing rar files......
WHERE /R %CD% *.rar > %RAR_RESULT%
FOR /F "DELIMS=" %%i IN (%RAR_RESULT%) DO (
    rem ECHO %%~dpi%%~ni >> %DIR_RESULT%
    ECHO %RAREXE% x %%i %%~dpi%%~ni
    IF NOT ERRORLEVEL 0 (
        ECHO Decompressing %%i Failed! 
        PAUSE
    )
)
DEL %RAR_RESULT%

ECHO=
ECHO Open project files......
ECHO=
WHERE /R %CD% *.sln > %SLN_RESULT%
FOR /F "DELIMS=" %%i IN (%SLN_RESULT%) DO (
    ECHO Open project file %%~ni%%~xi
    ECHO %VBEXE% %%i
        IF NOT ERRORLEVEL 0 (
        ECHO Open project file %%i Failed! 
        PAUSE
    )
    ECHO=
    ECHO Reopen project file %%~ni%%~xi
    ECHO %VBEXE% %%i
    IF NOT ERRORLEVEL 0 (
        ECHO Reopen project file %%i Failed! 
        PAUSE
    )
    SET /A COUNT-=1
    IF %COUNT% EQU 10 (
        ECHO !!!!!COUNT=%COUNT%!!!!
        SET /A COUNT=10
        PAUSE
    )
)
DEL %SLN_RESULT%

GOTO MYEXIT


:MYCLEAN


:MYEXIT
ECHO=
ECHO "EXIT????"
PAUSE