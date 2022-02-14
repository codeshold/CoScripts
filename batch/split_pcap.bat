@ECHO OFF
SET SEARCH_DIR=C:\
SET SEARCH_SOFTWARE=Wireshark.exe editcap.exe
SET SEARCH_RESULT=%TEMP%\editcap_path.tmp
SET EDITCAP_OUTFILE=split
SET OUTFILE_SUFFIX=
::1000000�����ݰ���Լ150M��50000�����ݰ�Լ6M
SET DEFAULT_PACKET_COUNT=50000
SET DEFAULT_PACKET_SIZE=6M

::RM %SEARCH_RESULT%
SETLOCAL enabledelayedexpansion

ECHO.
::ECHO Reading system informantion...
ECHO ��ʼ��ȡϵͳ��Ϣ����
IF NOT EXIST %SEARCH_RESULT% (
    WHERE /R %SEARCH_DIR% %SEARCH_SOFTWARE% > %SEARCH_RESULT%
)
::
FOR /F "DELIMS=" %%i in (%SEARCH_RESULT%) DO (
    IF "%%~ni%%~xi" == "editcap.exe" SET EDITCAP="%%i"
    IF "%%~ni%%~xi" == "Wireshark.exe" SET WIRESHARK="%%i"
)
::ECHO %EDITCAP% %WIRESHARK%
ECHO ϵͳ��Ϣ��ȡ��ϡ���

:input_filename
ECHO.
ECHO 1. �뽫Ҫ�и��pcap/pcapng�ļ�������ڣ�����Enter��ȷ�ϣ�
SET /P EDITCAP_INFILE=
IF "%EDITCAP_INFILE:~-6%"=="pcapng" SET OUTFILE_SUFFIX=.pcapng
IF "%EDITCAP_INFILE:~-4%"=="pcap" SET OUTFILE_SUFFIX=.pcap
IF "%OUTFILE_SUFFIX%"=="" GOTO input_filename

ECHO.
ECHO 2. ��ѡ���Ƿ�һ��ѡ������и����ʱ10��, Ĭ��ѡ y��
ECHO 1) �ǣ��밴 y
ECHO 2) ���ǣ��밴 n
ECHO 3) һ��ѡ�,�����ݰ����������и����ĵ����ļ�����%DEFAULT_PACKET_COUNT%�����ݰ���ԼΪ%DEFAULT_PACKET_SIZE%
CHOICE /C yn /T 10 /D y
IF %ERRORLEVEL% EQU 1 GOTO default_set_func 
IF %ERRORLEVEL% EQU 2 GOTO manual_set_func
:split_process
ECHO.
ECHO ��ʼ�и�pcap/pcapng�ļ�����
::file:///C:/Program%20Files%20(x86)/Wireshark/editcap.html
::ECHO %EDITCAP% %EDITCAP_PAR% %EDITCAP_INFILE% %EDITCAP_OUTFILE%%OUTFILE_SUFFIX%
%EDITCAP% %EDITCAP_PAR% %EDITCAP_INFILE% %EDITCAP_OUTFILE%%OUTFILE_SUFFIX%
::%EDITCAP% %EDITCAP_PAR% -F libpcap -T ether %EDITCAP_INFILE% %EDITCAP_OUTFILE%%OUTFILE_SUFFIX%
ECHO.
ECHO pcap/pcapng�ļ��и��������
ECHO.
SET /P END=��Enter������...
goto input_filename


:default_set_func
SET EDITCAP_PAR=-c %DEFAULT_PACKET_COUNT%
GOTO split_process


:manual_set_func
ECHO.
ECHO 3. ��ѡ���ļ��и�����͡�����ʱ10��, Ĭ��ѡ c����
ECHO 1) �����ݰ������и��밴 c
ECHO 2) ��ʱ�����и��밴 i
CHOICE /C ci /T 10 /D c
IF %ERRORLEVEL% EQU 1 (
    ECHO.
    ECHO 4. �����뵥���ļ������ݰ�����������Enterȷ�ϣ�
    SET /P PACKET_COUNT=
    SET EDITCAP_PAR=-c !PACKET_COUNT!
) ELSE (
    ECHO.
    ECHO 4. �����뵥���ļ���ʱ��������λ�룩������Enterȷ�ϣ�
    SET /P PACKET_INTERVAL=
    SET EDITCAP_PAR=-i !PACKET_INTERVAL!
)
GOTO split_process




