@echo off
echo.
echo 1.设置寝室静态IP
echo 2.设置实验室静态IP
echo 3.设置自动获取IP
echo 4.设置XXX静态IP
echo 5.设置逸夫楼二楼IP
echo 6.设置XXX机房静态IP
echo 0.exit
echo.
set /P i=请输入对应操作编号:

::set IPADDR=10.100.222.67
::set NETMASK=255.255.255.0
::set GATEWAY=10.100.222.254
set DNS1=202.120.224.6
set DNS2=61.129.42.6
set NAME="本地连接 4"

if %i% EQU 0 ( exit )
echo 设置中…………
if %i% EQU 1 (
    netsh interface ipv4 set address name=%NAME% static 10.100.222.67 255.255.255.0 10.100.222.254
    netsh interface ipv4 set dnsservers %NAME% static %DNS1%
    netsh interface ipv4 add dnsservers %NAME% %DNS2%
)
if %i% EQU 2 (
    netsh interface ipv4 set address name=%NAME% static 10.10.82.155 255.255.255.0 10.10.82.1
    netsh interface ipv4 set dnsservers %NAME% static %DNS1%
    netsh interface ipv4 add dnsservers %NAME% %DNS2%
)
if %i% EQU 3 (
    netsh interface ipv4 set address name=%NAME% source=dhcp
    netsh interface ipv4 set dnsservers %NAME% source=dhcp
)
if %i% EQU 4 (
    netsh interface ipv4 set address name=%NAME% static 12.113.48.201 255.255.255.0 12.113.48.1
    netsh interface ipv4 set dnsservers %NAME% static 12.113.250.253
    netsh interface ipv4 add dnsservers %NAME% 12.113.250.254
)
if %i% EQU 5 (
    netsh interface ipv4 set address name=%NAME% static 10.20.2.96 255.255.255.0 10.20.2.1
    netsh interface ipv4 set dnsservers %NAME% static 114.114.114.114
    netsh interface ipv4 add dnsservers %NAME% 12.113.250.254
)
if %i% EQU 6 (
    netsh interface ipv4 set address name=%NAME% static 12.113.45.189 255.255.255.0 12.113.45.1
    netsh interface ipv4 set dnsservers %NAME% static 114.114.114.114
    netsh interface ipv4 add dnsservers %NAME% 12.113.250.254
)
exit
