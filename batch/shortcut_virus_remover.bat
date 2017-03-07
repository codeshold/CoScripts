@echo off
title 中毒U盘恢复程序（快捷方式病毒）


:start
echo.
echo 请输入U盘对应的磁盘符号(如F)
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
echo 正在恢复被隐藏的文件...
attrib /s /d -s -h -a %drive%:\*.*

echo.
echo 正在删除快捷方式...
del /a /q /s %drive%:\*.lnk

echo.
echo 正在删除vbs病毒文件...
del /a /q /s %drive%:\*.vbs

echo.
echo U盘修复成功! (有问题欢迎邮件wuzhimang@gmail.com)
echo.
echo 按任意键退出
set /p "end="
goto end

:warning
echo.
echo U盘标签未发现
echo.
echo 请插入U盘或输入正确的标签
echo.

pause

:end