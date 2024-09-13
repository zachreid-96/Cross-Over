@echo off
:: BatchGotAdmin
:: -------------------------------------
:: Thanks Ben Gripka and dbenham for the following
:: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file
:: REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

:: REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

:: -------------------------------------

:: Stylistic section of the program, turns echo off so these commands do not appear in CMD
@echo off
title IPv4 Copier Cross-Over by Zach
setlocal EnableExtensions EnableDelayedExpansion
color B
echo.

:: Outputs general information about the program and that this needs Admin rights to change IP successfully

echo:
echo This batch file has simple checks to ensure a proper IP address is entered
echo After an IP address is obtained, if valid, it will set your IP address
echo   Then the script will close and open the Copier EWS (Embedded Web Server)
echo:

:: Here are some variables that need accessed in other functions, just stored here in case
set NL=^
echo:
set IPArr=[]

set SUBNETArr[0]=255
set SUBNETArr[1]=255
set SUBNETArr[2]=255
set SUBNETArr[3]=0

set /a pCount=0
set ip=0

:: The only function that doesn't need called
:: This prints the option menu and calls the correct function given a choice

:printMenu
	echo This program has a few options...
	echo Changing IP will also open the EWS for the copier
	echo   1) Change IP with default SUBNET
	echo   2) Change IP with custom SUBNET
	echo   3) Revert Network Settings back to DHCP
	echo   4) Troubleshoot script
	echo   5) Check for updates
	echo   6) Submit bug report or request new feature
	echo:
	set /p "option=Enter 1-5: " || set "option=2"
	echo:
	
	:: Get-NetConnectionProfile -InterfaceAlias "Network" | Set-NetConnectionProfile -NetworkCategory Private -Confirm:$false -PassThru
	:: Try the above command to set connection to private instead of public
	:: might not be an issue but will need testing
	
	if %option%==1 (
		goto :getIP
	) else if %option%==2 (
		goto :getIP_SUBNET
	) else if %option%==3 (
		goto :setDHCP
	) else if %option%==4 (
		goto :printErrorCodes
		exit
	) else if %option%==5 (
		call :setDHCP_Error "[FINISH_UPDATE_CHECK_SECTION"
		exit
	) else if %option%==6 (
		call :setDHCP_Error "[FINISH_FEATURE_BUG_SECTION"
		exit
	) else (
		call :setDHCP_Error "[MENU_INVALID_SELECTION_ERROR]"
		exit
	)

:printErrorCodes
	
	echo:
	echo Here is a list of the error codes and what they mean...
	echo:
	
	echo ERROR_CODE: IP_NULL_ERROR
	echo DESCRIPTION: The IP address was entered as null.
	echo:
	echo ERROR_CODE: IP_MISSING_OCTETS_ERROR
	echo DESCRIPTION: The IP address is missing one or more octets.
	echo:
	echo ERROR_CODE: IP_TOO_MANY_OCTETS_ERROR
	echo DESCRIPTION: The IP address has too many octets.
	echo:
	echo ERROR_CODE: SUBNET_MISSING_OCTETS_ERROR
	echo DESCRIPTION: The SUBNET address is missing one or more octets.
	echo:
	echo ERROR_CODE: SUBNET_TOO_MANY_OCTETS_ERROR
	echo DESCRIPTION: The SUBNET address has too many octets.
	echo:
	echo ERROR_CODE: SUBNET_NULL_ERROR
	echo DESCRIPTION: The SUBNET address was entered as null.
	echo:
	echo ERROR_CODE: IP_INVALID_OCTET_ERROR
	echo DESCRIPTION: The IP address contains an invalid octet.
	echo:
	echo ERROR_CODE: SUBNET_INVALID_OCTET_ERROR
	echo DESCRIPTION: The SUBNET address contains an invalid octet.
	echo:
	echo ERROR_CODE: MENU_INVALID_SELECTION_ERROR
	echo DESCRIPTION: An invalid menu selection was picked.
	echo:
	echo ERROR_CODE: ADMIN_RIGHTS_NOT_GRANTED
	echo DESCRIPTION: This script was not run with Admin Rights.
	echo:
	call :setDHCP_Error "[DISPLAYED_ERROR_CODE_LIST]"

:: This function asks the user for the copier IP then sends it to :splitIP
:getIP
	echo Please enter Copier IP in following format 10.120.1.68
	echo:
	
	set /p "ip=Enter IP Address: " || set "ip=0.0.0.0"
	echo:
	
	:: If no IP is entered, a defualt 0.0.0.0 IP is set and the program will exit
	if "%ip%"=="0.0.0.0" (
		call :setDHCP_Error "[IP_NULL_INPUT_ERROR]"
		exit
	)
	if not "%ip%"=="0.0.0.0" (
		call :splitIP []
	)
	
:getIP_SUBNET
	echo Please enter the Copier IP in the following format 10.120.1.68
	echo:
	set /p "ip=Enter IP Address: " || set "ip=0.0.0.0"
	echo:
	
	if "%ip%"=="0.0.0.0" (
		call :setDHCP_Error "[IP_NULL_INPUT_ERROR]"
		exit
	)
	
	echo Please enter the Copier SUBNET in the following format 255.255.254.0
	echo:
	set /p "subnet=Enter SUBNET: " || set "subnet=0.0.0.0"
	echo:
	if "%subnet%"=="0.0.0.0" (
		call :setDHCP_Error "[SUBNET_NULL_INPUT_ERROR]"
		exit
	)
	
	call :splitIP %subnet%
	exit

:: This splits the IP into an array, stored in IPArr made above
:: Essentially goes through and counts each period "." if more than 3 the IP is Invalid
:: This also tediously loops through the IP entered and splits 192.168.1.5 into 192 168 1 5
:: 		Tedious because Batch doesn't natively support splitting by multiple "."
:: Once it hits a "" or undefined character it will go to :validateIP
:splitIP
	set g=
	for /l %%i in (0,1,20) do (
		if !pCount! geq 4 (
			call :setDHCP_Error "[IP_EXCESS_OCTET_ERROR]"
		)
		set t=!ip:~%%i,1!
		if "!t!"=="" (
			if !pCount! neq 3 call :setDHCP_Error "[IP_MISSING_OCTET_ERROR]"
			if %~1 neq [] goto :splitSUBNET
			goto :validateIP
		) else if "!t!"=="." (
			::set IPArr[!pCount!]=!g!
			set /a pCount=pCount+1
			set g=
		) else (
			set "g=!g!!t!"
			set IPArr[!pCount!]=!g!
		)
	)
	
:splitSUBNET
	echo visited
	set pCount=0
	set subnet=%~1
	set SUBNETArr=[]
	set g=
	for /l %%i in (0,1,20) do (
		if !pCount! gtr 3 (
			call :setDHCP_Error "[SUBNET_EXCESS_OCTET_ERROR]"
		)
		set t=!subnet:~%%i,1!
		if "!t!"=="" (
			if !pCount! neq 3 call :setDHCP_Error "[SUBNET_MISSING_OCTET_ERROR]"
			goto :validateIP_SUBNET
		) else if "!t!"=="." (
			::set IPArr[!pCount!]=!g!
			set /a pCount=pCount+1
			set g=
		) else (
			set "g=!g!!t!"
			set SUBNETArr[!pCount!]=!g!
		)
	)

:: Loops through each number and verifies it is between 0 and 255
:: Will exit if a number is invalid and prompt to restart
:: This will also detect the last IP number and assign your Laptop IP x.x.x.25 if Copier IP is not x.x.x.25
:: 		This will assign Laptop IP x.x.x.35 if Copier IP is x.x.x.25
:: Trust the process here
:validateIP
	if !IPArr[3]!==25 (
		set IPArr[3]=35
	) else (
		set IPArr[3]=25
	)
	
	set nope=0
	
	if !IPArr[0]! leq 1 set nope=1
	if !IPArr[0]! gtr 255 set nope=1
	if !IPArr[1]! leq 0 set nope=1
	if !IPArr[1]! gtr 255 set nope=1
	if !IPArr[2]! leq 0 set nope=1
	if !IPArr[2]! gtr 255 set nope=1
	
	if nope==1 (
		call :setDHCP_Error "[IP_INVALID_OCTET_ERROR]"
		exit
	)
	
	goto :changeIP
	exit

:validateIP_SUBNET

	if !IPArr[3]!==25 (
		set IPArr[3]=35
	) else (
		set IPArr[3]=25
	)
	
	set IP_nope=0
	
	if !IPArr[0]! leq 1 set IP_nope=1
	if !IPArr[0]! gtr 255 set IP_nope=1
	if !IPArr[1]! leq 0 set IP_nope=1
	if !IPArr[1]! gtr 255 set IP_nope=1
	if !IPArr[2]! leq 0 set IP_nope=1
	if !IPArr[2]! gtr 255 set IP_nope=1
	
	if IP_nope==1 (
		call :setDHCP_Error "[IP_INVALID_OCTET_ERROR]"
		exit
	)
	
	set SUBNET_nope=0
	
	if !SUBNETArr[0]! leq 1 set SUBNET_nope=1
	if !SUBNETArr[0]! gtr 255 set SUBNET_nope=1
	if !SUBNETArr[1]! leq 0 set SUBNET_nope=1
	if !SUBNETArr[1]! gtr 255 set SUBNET_nope=1
	if !SUBNETArr[2]! leq 0 set SUBNET_nope=1
	if !SUBNETArr[2]! gtr 255 set SUBNET_nope=1
	if !SUBNETArr[3]! leq 0 set SUBNET_nope=1
	if !SUBNETArr[3]! gtr 255 set SUBNET_nope=1
	
	if SUBNET_nope==1 (
		call :setDHCP_Error "[SUBNET_INVALID_OCTET_ERROR]"
		exit
	)
	
	goto :changeIP
	exit

:: This actually sets the IPv4 address of your Laptop and open the Copier EWS
:: Probably best to reset settings back to DHCP then set for entered IP
:changeIP
	set newIp=%IPArr[0]%.%IPArr[1]%.%IPArr[2]%.%IPArr[3]%
	set newSUBNET=!SUBNETArr[0]!.!SUBNETArr[1]!.!SUBNETArr[2]!.!SUBNETArr[3]!
	netsh interface ipv4 set address name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set subnet name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set address name="Ethernet" static %newIp% %newSUBNET% >nul 2>&1
	echo Cross-over ready. Press any key to exit and open EWS...
	pause>nul | echo:
	start "" https://%ip%
	exit

:setDHCP_Error
	netsh interface ipv4 set address name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set subnet name="Ethernet" dhcp >nul 2>&1
	echo %~1 Press any key to exit...
	pause>nul | echo:
	exit
	
:: This sets IPv4 address and SUBNET back to DHCP
:setDHCP
	netsh interface ipv4 set address name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set subnet name="Ethernet" dhcp >nul 2>&1
	echo Set IPv4 Settings back to DHCP. Press any key to exit...
	pause>nul | echo:
	exit

exit
