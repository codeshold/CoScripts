@ECHO OFF
SET SEARCH_DIR=C:\
SET SEARCH_SOFTWARE=Wireshark.exe editcap.exe
SET SEARCH_RESULT=%TEMP%\editcap_path.tmp
SET EDITCAP_OUTFILE=split
SET OUTFILE_SUFFIX=
::1000000个数据包，约150M，50000个数据包约6M
SET DEFAULT_PACKET_COUNT=50000
SET DEFAULT_PACKET_SIZE=6M

::RM %SEARCH_RESULT%
SETLOCAL enabledelayedexpansion

ECHO.
::ECHO Reading system informantion...
ECHO 开始读取系统信息……
IF NOT EXIST %SEARCH_RESULT% (
    WHERE /R %SEARCH_DIR% %SEARCH_SOFTWARE% > %SEARCH_RESULT%
)
::
FOR /F "DELIMS=" %%i in (%SEARCH_RESULT%) DO (
    IF "%%~ni%%~xi" == "editcap.exe" SET EDITCAP="%%i"
    IF "%%~ni%%~xi" == "Wireshark.exe" SET WIRESHARK="%%i"
)
::ECHO %EDITCAP% %WIRESHARK%
ECHO 系统信息读取完毕……

:input_filename
ECHO.
ECHO 1. 请将要切割的pcap/pcapng文件拖入框内，并按Enter键确认：
SET /P EDITCAP_INFILE=
IF "%EDITCAP_INFILE:~-6%"=="pcapng" SET OUTFILE_SUFFIX=.pcapng
IF "%EDITCAP_INFILE:~-4%"=="pcap" SET OUTFILE_SUFFIX=.pcap
IF "%OUTFILE_SUFFIX%"=="" GOTO input_filename

ECHO.
ECHO 2. 请选择是否按一般选项进行切割【倒计时10秒, 默认选 y】
ECHO 1) 是，请按 y
ECHO 2) 不是，请按 n
ECHO 3) 一般选项即,按数据包个数进行切割，输出的单个文件包含%DEFAULT_PACKET_COUNT%个数据包，约为%DEFAULT_PACKET_SIZE%
CHOICE /C yn /T 10 /D y
IF %ERRORLEVEL% EQU 1 GOTO default_set_func 
IF %ERRORLEVEL% EQU 2 GOTO manual_set_func
:split_process
ECHO.
ECHO 开始切割pcap/pcapng文件……
::file:///C:/Program%20Files%20(x86)/Wireshark/editcap.html
::ECHO %EDITCAP% %EDITCAP_PAR% %EDITCAP_INFILE% %EDITCAP_OUTFILE%%OUTFILE_SUFFIX%
%EDITCAP% %EDITCAP_PAR% %EDITCAP_INFILE% %EDITCAP_OUTFILE%%OUTFILE_SUFFIX%
::%EDITCAP% %EDITCAP_PAR% -F libpcap -T ether %EDITCAP_INFILE% %EDITCAP_OUTFILE%%OUTFILE_SUFFIX%
ECHO.
ECHO pcap/pcapng文件切割结束……
ECHO.
SET /P END=按Enter键继续...
goto input_filename


:default_set_func
SET EDITCAP_PAR=-c %DEFAULT_PACKET_COUNT%
GOTO split_process


:manual_set_func
ECHO.
ECHO 3. 请选择文件切割的类型【倒计时10秒, 默认选 c】：
ECHO 1) 按数据包个数切割请按 c
ECHO 2) 按时间间隔切割请按 i
CHOICE /C ci /T 10 /D c
IF %ERRORLEVEL% EQU 1 (
    ECHO.
    ECHO 4. 请输入单个文件的数据包个数，并按Enter确认：
    SET /P PACKET_COUNT=
    SET EDITCAP_PAR=-c !PACKET_COUNT!
) ELSE (
    ECHO.
    ECHO 4. 请输入单个文件的时间间隔（单位秒），并按Enter确认：
    SET /P PACKET_INTERVAL=
    SET EDITCAP_PAR=-i !PACKET_INTERVAL!
)
GOTO split_process




