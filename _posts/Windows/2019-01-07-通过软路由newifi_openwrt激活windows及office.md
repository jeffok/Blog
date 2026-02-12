---
title: 通过软路由newifi_openwrt激活windows及office
date: 2019-01-07 14:06:00
tags: ["批处理", "Windows"]
categories: ["Windows"]
render_with_liquid: false
permalink: /posts/2019-01-07-通过软路由newifi_openwrt激活windows及office/
---
首先，保证你的WINDOWS系统和OFFICE是VOL版的，这样才可以激活。

WINDOWS系统除了旗舰版和家庭版都能激活。（我使用WIN10 专业版）

OFFICE 2016在MSDN只有专业增强版，下载进来并安装，

使用“OFFICE2016转VOL版.bat”这个批处理文件能将OFFICE转为VOL版

## WINDOWS激活

- **第一步**：打开DOS或powershell，输入slmgr /upk，卸载WINDOWS自带密钥

- **第二步**：输入slmgr /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX

(在上面key列表选择对应版本的Key，也可以搜索找对应版本key)

安装对应密钥

常用Windows VL版KMS激活密钥列表：

Win10专业版KMS： W269N-WFGWX-YVC9B-4J6C9-T83GX

Win10企业版KMS： NPPR9-FWDCX-D2C8J-H872K-2YT43

Win10LTSB版KMS： DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ

Win10家庭版KMS： TX9XD-98N7V-6WMQ6-BX7FG-H8Q99

Win10教育版KMS： NW6C2-QMPVW-D7KKK-3GKT6-VCFB2

Win7专业版KMS： FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4

Win7企业版KMS： 33PXH-7Y6KF-2VJC9-XBBR8-HVTHH

- **第三步**：slmgr /skms 192.168.1.1（路由器IP地址）

- **第四步**：slmgr /ato

## OFFICE激活

### **第一步**：找到你的OFFICE目录

我的是OFFICE 2016 32位版，目录为：

C:\Program Files (x86)\Microsoft Office\Office16

进去这个目录，可以看见有个OSPP.VBS文件

如果是OFFICE 2016 64位版，目录应为：

C:\Program Files\Microsoft Office\Office16

- **第二步**：powershell中cd “C:\Program Files (x86)\Microsoft Office\Office16”（双引号中对应你的实际目录）

- **第三步**：输入cscript ospp.vbs /sethst:192.168.1.1（你的路由IP）

- **第四步**：输入cscript ospp.vbs /act

```bash
# 2012 r2 Datacenter

slmgr /upk
slmgr /ipk W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9
slmgr /skms 10.224.100.50
slmgr /ato

```

## OFFICE2016转VOL版.bat

```bash
@ECHO OFF&PUSHD %~DP0

setlocal EnableDelayedExpansion&color 3e & cd /d "%~dp0"
title office2016 retail转换vol版

%1 %2
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :runas","","runas",1)(window.close)&goto :eof
:runas

if exist "%ProgramFiles%\Microsoft Office\Office16\ospp.vbs" cd /d "%ProgramFiles%\Microsoft Office\Office16"
if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs" cd /d "%ProgramFiles(x86)%\Microsoft Office\Office16"

:WH
cls
echo.
echo                        选择需要转化的office版本序号
echo.
echo --------------------------------------------------------------------------------
echo                1. 零售版 Office Pro Plus 2016 转化为VOL版
echo.
echo                2. 零售版 Office Visio Pro 2016 转化为VOL版
echo.
echo                3. 零售版 Office Project Pro 2016 转化为VOL版
echo.
echo. --------------------------------------------------------------------------------

set /p tsk="请输入需要转化的office版本序号【回车】确认（1-3）: "
if not defined tsk goto:err
if %tsk%==1 goto:1
if %tsk%==2 goto:2
if %tsk%==3 goto:3

:err
goto:WH

:1
cls

echo 正在重置Office2016零售激活...
cscript ospp.vbs /rearm

echo 正在安装 KMS 许可证...
for /f %%x in ('dir /b ..\root\Licenses16\proplusvl_kms*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul

echo 正在安装 MAK 许可证...
for /f %%x in ('dir /b ..\root\Licenses16\proplusvl_mak*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul

echo 正在安装 KMS 密钥...
cscript ospp.vbs /inpkey:XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99

goto :e

:2
cls

echo 正在重置Visio2016零售激活...
cscript ospp.vbs /rearm

echo 正在安装 KMS 许可证...
for /f %%x in ('dir /b ..\root\Licenses16\visio???vl_kms*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul

echo 正在安装 MAK 许可证...
for /f %%x in ('dir /b ..\root\Licenses16\visio???vl_mak*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul

echo 正在安装 KMS 密钥...
cscript ospp.vbs /inpkey:PD3PC-RHNGV-FXJ29-8JK7D-RJRJK

goto :e

:3
cls

echo 正在重置Project2016零售激活...
cscript ospp.vbs /rearm

echo 正在安装 KMS 许可证...
for /f %%x in ('dir /b ..\root\Licenses16\project???vl_kms*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul

echo 正在安装 MAK 许可证...
for /f %%x in ('dir /b ..\root\Licenses16\project???vl_mak*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul

echo 正在安装 KMS 密钥...
cscript ospp.vbs /inpkey:YG9NW-3K39V-2T3HJ-93F3Q-G83KT

goto :e

:e
cscript //nologo ospp.vbs /sethst:kms.03k.org
cscript //nologo ospp.vbs /act
echo.
echo 转化完成，按任意键退出！

```
