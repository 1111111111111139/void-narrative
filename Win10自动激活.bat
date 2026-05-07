@echo off
:: 你可以使用文本编辑器（例如记事本）编辑该批处理文件
:: 按照下列格式添加新的 KMS 服务器。不分顺序。

::已说过长期有效
set a1=54.223.212.31
set a2=kms.guowaifuli.com
set a3=mhd.kmdns.net
set a4=xykz.f3322.org

::未说长期有效
set a5=106.186.25.239
set a6=110.noip.me
set a7=3rss.vicp.net:20439
set a8=45.78.3.223
set a9=kms.chinancce.com
set a10=kms.didichuxing.com
set a11=skms.ddns.net
set a12=zh.us.to

::分时段有效
set a13=franklv.ddns.net
set a14=k.zpale.com
set a15=m.zpale.com
set a16=mvg.zpale.com

::我2015-8-26测试时已经失效，不排除不巧遇到短时失效 及以后复活的可能
set a17=122.226.152.230
set a18=222.76.251.188
set a19=annychen.pw
set a20=heu168.6655.la
set a21=kms.aglc.cc
set a22=kms.landiannews.com
set a23=kms.shuax.com
set a24=kms.xspace.in
set a25=winkms.tk
set a26=wrlong.com

:: 最多可以设置 50 个KMS服务器

::======================= 以下内容无需更改 ======================
mode con cols=85 lines=25
setlocal EnableDelayedExpansion&color 3e
title KMS_Activation for Win10 - [hnfeng]
%1 %2
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :runas","","runas",1)(window.close)&goto :eof
:runas
call :strset
call :netchk
call :verchk
call :setkey

if not defined str1 goto en
echo %bar%%bar%%bar%
echo    %str1% &echo.&echo    %str2%&echo.&echo    %str11%
echo.&echo                                             2015-8, hnfeng
echo %bar%%bar%%bar%
timeout /t 10
:en
for /f "tokens=3 delims= " %%i in ('reg QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "EditionID"') do set EditionID=%%i
if defined %EditionID% (echo.
	cscript //Nologo %windir%\system32\slmgr.vbs /ipk !%EditionID%!
	for /L %%a in (1,1,50) do (if defined a%%a (echo %bar%%bar% &echo %str3% !a%%a! &echo.
		cscript //Nologo %windir%\system32\slmgr.vbs /skms !a%%a!
		(cscript //nologo %windir%\system32\slmgr.vbs /ato) ^| findstr /i "successful 成功 Θ" && (call :successful !a%%a!)))
       	goto failure) else (echo.&echo %str4% "%EditionID%" &echo.&echo %bar9% & pause>nul)
exit

:setkey
set Core=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
set CoreCountrySpecific=PVMJN-6DFY6-9CCP6-7BKTT-D3WVR
set CoreN=3KHY7-WNT83-DGQKR-F7HPR-844BM
set CoreSingleLanguage=7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH
set ProfessionalStudent=YNXW3-HV3VB-Y83VG-KPBXM-6VH3Q
set ProfessionalStudentN=8G9XJ-GN6PJ-GW787-MVV7G-GMR99
set Professional=W269N-WFGWX-YVC9B-4J6C9-T83GX
set ProfessionalN=MH37W-N47XK-V7XM9-C7227-GCQG9
set ProfessionalSN=8Q36Y-N2F39-HRMHT-4XW33-TCQR4
set ProfessionalWMC=NKPM6-TCVPT-3HRFX-Q4H9B-QJ34Y
set Enterprise=NPPR9-FWDCX-D2C8J-H872K-2YT43
set EnterpriseN=DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4
set Education=NW6C2-QMPVW-D7KKK-3GKT6-VCFB2
set EducationN=2WH4N-8QGBV-H22JP-CT43Q-MDWWJ
set EnterpriseS=WNMTR-4C88C-JK8YV-HQ7T2-76DF9
set EnterpriseSN=2F77B-TNFGY-69QQF-B8YKP-D69TJ
goto :EOF

:strset
chcp | find "936" > nul && (
	set bar=======================
	set str1=自动检查 Win10 的版本，导入对应的 KMS 密钥
	set str2=然后自动逐个尝试 KMS 服务器来激活 Win10
	set str3=正在尝试的 KMS 服务器: 
	set str4=未发现对应当前系统版本所定义的密钥: 
	set str5=恭喜！已经成功激活！
	set str6=运气不佳哦，KMS 服务器全部无法连接，激活失败。
	set str7=当前操作系统不是 Windows 10. 
	set str8=请检查网络是否通畅。
	set str9=按任意键退出...
	set str10=使用的 KMS 服务器是:
	set str11=若激活成功，背景变红色。若失败，背景变蓝色。
	set str12=正在检测网络，请稍等...
)
chcp | find "950" > nul && (
	set bar=======================
	set str1=笆浪琩 Win10 セ旧癸莱 KMS 盞芲
	set str2=礛笆硋沽刚 KMS 狝叭竟ㄓ縀 Win10
	set str3=タ沽刚 KMS 狝叭竟: 
	set str4=ゼ祇瞷癸莱讽玡╰参セ┮﹚竡盞芲: 
	set str5=尺, 竒Θ币ノ
	set str6=笲蒩ぃㄎ瓳KMS 狝叭竟场礚猭硈钡币ノア毖
	set str7=讽玡巨╰参ぃ琌 Windows 10. 
	set str8=叫浪琩蔍蹈琌硄篫
	set str9=ヴ種龄癶...
	set str10=ㄏノ KMS 狝叭竟琌:
	set str11=璝縀Θ璉春跑︹璝ア毖璉春跑屡︹
	set str12=タ浪代蔍蹈叫祔单...
)
chcp | find "437" > nul && (
	set bar=======================
	set str3=Trying KMS server: 
	set str4=The defined key is not found: 
	set str5=Ha-ha, Product activation successful.
	set str6=Sorry, Activation failure. 
	set str7=The current OS is NOT Windows 10.
	set str8=Please check if the network is open.
	set str9=Press any key to exit...
	set str10=The KMS server is:
	set str12=Checking the network, Please wait a moment...
)
if not defined str3 (
	echo.&echo Unsupported system language.
	echo.&echo This BAT just support Chinese[CN, HK, TW] and English.
	echo.&echo %str9% &pause>nul)
goto :EOF

:failure
cls&color 1e
echo.&echo %bar%%bar%%bar%
echo %str6% &echo.&echo %str8%
echo %bar%%bar%%bar%&echo.
echo %str9% & pause>nul
exit

:successful
cls&color ce
echo.&echo %bar%%bar%%bar%
echo %str5% &echo.&echo %str10% %1
echo %bar%%bar%%bar%&echo.
echo %str9% & pause>nul
exit

:netchk
echo %str12%
ping -n 1 www.qq.com | find /i "TTL" > nul && (cls & goto :EOF)
ping -n 1 www.baidu.com | find /i "TTL" > nul && (cls & goto :EOF)
echo.&echo %str8% & echo. & echo %str9% & pause>nul
exit

:verchk
ver | find "10.0." >nul 2>nul && (goto :EOF)
echo.&echo %str7% &echo.&pause &exit
