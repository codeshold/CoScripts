@echo off
title �ж�U�ָ̻����򣨿�ݷ�ʽ������


:start
echo.
echo ������U�̶�Ӧ�Ĵ��̷���(��F)
set /p drive=
if exist %drive%:\ (
    if "%drive%"=="C" goto warning
    if "%drive%"=="c" goto warning
    goto dealing
) else (
    goto warning
)


:dealing
echo.
echo ���ڻָ������ص��ļ�...
attrib /s /d -s -h -a %drive%:\*.*

echo.
echo ����ɾ����ݷ�ʽ...
del /a /q /s %drive%:\*.lnk

echo.
echo ����ɾ��vbs�����ļ�...
del /a /q /s %drive%:\*.vbs

echo.
echo U���޸��ɹ�! (�����⻶ӭ�ʼ�wuzhimang@gmail.com)
echo.
echo ��������˳�
set /p "end="
goto end

:warning
echo.
echo U�̱�ǩδ����
echo.
echo �����U�̻�������ȷ�ı�ǩ
echo.

pause

:end