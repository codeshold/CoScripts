@echo off
echo.
echo 1.�������Ҿ�̬IP
echo 2.����ʵ���Ҿ�̬IP
echo 3.�����Զ���ȡIP
echo 4.����XXX��̬IP
echo 5.�����ݷ�¥��¥IP
echo 6.����XXX������̬IP
echo 0.exit
echo.
set /P i=�������Ӧ�������:

::set IPADDR=10.100.222.67
::set NETMASK=255.255.255.0
::set GATEWAY=10.100.222.254
set DNS1=202.120.224.6
set DNS2=61.129.42.6
set NAME="�������� 4"

if %i% EQU 0 ( exit )
echo �����С�������
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
