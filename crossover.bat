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
set version=3.1.4
title IPv4 Copier Cross-Over by Zach (v%version%)
setlocal EnableExtensions EnableDelayedExpansion
color B
echo.

:: Outputs general information about the program and that this needs Admin rights to change IP successfully

echo.
echo This batch file has simple checks to ensure a proper IP address is entered
echo After an IP address is obtained, if valid, it will set your IP address
echo   Then the script will close and open the Copier EWS (Embedded Web Server)
echo.

:: Here are some variables that need accessed in other functions, just stored here in case
:: IPArr - used to split the IP into its octets in :splitIP, validate octets in :validateIP, and create newIP in :changeIP and :print_event_log
set NL=^
echo.
set IPArr=[]

:: Initializes subnet array in case of manipulation
set SUBNETArr[0]=255
set SUBNETArr[1]=255
set SUBNETArr[2]=255
set SUBNETArr[3]=0

:: Initializes variables that will be used
:: pCount - used to count the periods in :splitIP
:: ip - used to store user entered IP in :getIP and :getIP_SUBNET
:: event_log - used to bypass end of script and execute :print_event_log
:: event_log_skip - used to bypass IP verification and print event log in :print_event_log (assumes already crossed-over)
set /a pCount=0
set ip=0
set event_log=0
set event_log_skip=0

:: The only function that doesn't need called
:: This prints the option menu and calls the correct function given user choice
:: Option 99 is not output but is a valid choice to check for updates

:printMenu
	echo This program has a few options...
	echo Changing IP will also open the EWS for the copier
	echo   1) Change IP with default SUBNET
	echo   2) Change IP with custom SUBNET
	echo   3) Revert Network Settings back to DHCP
	echo   4) Troubleshoot script
	echo   5) Cross Over and Print Event Log
	echo   6) Print Event Log (already crossed over)
	:: echo   99) Check for updates
	echo.
	set /p "option=Enter 1-6: " || set "option=3"
	echo.
	
	:: If invalid choice, will set back to DHCP via :setDHCP_Error and display error code
	:: If valid choice, will call appropriate function
	
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
		set event_log=1
		goto :getIP
	) else if %option%==6 (
		set event_log_skip=1
		goto :getIP
	) else if %option%==99 (
		echo Current version is %version%
		set /p "update=Press Enter to Check for Updates"
		start "" https://github.com/zachreid-96/Cross-Over
		exit
	) else (
		call :setDHCP_Error "[MENU_INVALID_SELECTION_ERROR]"
		exit
	)

:: Here is the list of pre-programmed error codes
:: This will be output as option 4 and can help identify what went wrong
:: Examples are also provided

:printErrorCodes
	
	echo.
	echo Here is a list of the error codes and what they mean...
	echo.
	
	echo ERROR_CODE: IP_NULL_ERROR
	echo DESCRIPTION: The IP address was entered as null.
	echo EXAMPLE: 0.0.0.0
	echo.
	echo ERROR_CODE: IP_MISSING_OCTETS_ERROR
	echo DESCRIPTION: The IP address is missing one or more octets.
	echo EXAMPLE: 192.168.1. or 192..1.25
	echo.
	echo ERROR_CODE: IP_TOO_MANY_OCTETS_ERROR
	echo DESCRIPTION: The IP address has too many octets.
	echo EXAMPLE: 19.2.168.1.25
	echo.
	echo ERROR_CODE: SUBNET_MISSING_OCTETS_ERROR
	echo DESCRIPTION: The SUBNET address is missing one or more octets.
	echo EXAMPLE: 255.255.0
	echo.
	echo ERROR_CODE: SUBNET_TOO_MANY_OCTETS_ERROR
	echo DESCRIPTION: The SUBNET address has too many octets.
	echo EXAMPLE: 255.255.255. or 255.25.5.255.0
	echo.
	echo ERROR_CODE: SUBNET_NULL_ERROR
	echo DESCRIPTION: The SUBNET address was entered as null.
	echo EXAMPLE: 0.0.0.0
	echo.
	echo ERROR_CODE: IP_INVALID_OCTET_ERROR
	echo DESCRIPTION: The IP address contains an invalid octet.
	echo EXAMPLE: 192.1680.1.25
	echo.
	echo ERROR_CODE: SUBNET_INVALID_OCTET_ERROR
	echo DESCRIPTION: The SUBNET address contains an invalid octet.
	echo EXAMPLE: 255.255.2550.0
	echo.
	echo ERROR_CODE: MENU_INVALID_SELECTION_ERROR
	echo DESCRIPTION: An invalid menu selection was picked.
	echo EXAMPLE: Any option outside of 1-6
	echo.
	echo ERROR_CODE: LPR_NOT_ENABLED_ERROR
	echo DESCRIPTION: LPR is not enabled.
	echo Please enable LPR and run again.
	echo.
	echo ERROR_CODE: MAX_PING_TIMEOUT_ERROR
	echo DESCRIPTION: Max ping attempt of 25 was reached when attempting to cross over.
	echo Please double check IP and run again, set to DHCP.
	echo.
	echo ERROR_CODE: LPR_NOT_ENABLED_ERROR
	echo DESCRIPTION: LPR is enabled, but cannot ping machine.
	echo Please double check network settings on copier/printer and on PC.
	echo.
	echo Press any key to exit...
	pause>nul | echo.
	exit

:: This function asks the user for the copier IP then sends it to :splitIP
:: If no input is entered a default entry of 0.0.0.0 is entered
:: This will then set to DHCP and output an error code before exiting intentionally

:getIP
	echo Please enter Copier IP in following format 10.120.1.68
	echo.
	
	set /p "ip=Enter IP Address: " || set "ip=0.0.0.0"
	echo.
	
	:: If no IP is entered, a defualt 0.0.0.0 IP is set and the program will exit
	if "%ip%"=="0.0.0.0" (
		call :setDHCP_Error "[IP_NULL_INPUT_ERROR]"
		exit
	)
	if not "%ip%"=="0.0.0.0" (
		call :splitIP []
	)

:: Similar to :getIP function call
:: This will ask the user for the IP and Subnet desired
:: If no input is entered for either it will set to DHCP and output and error code

:getIP_SUBNET
	echo Please enter the Copier IP in the following format 10.120.1.68
	echo.
	set /p "ip=Enter IP Address: " || set "ip=0.0.0.0"
	echo.
	
	if "%ip%"=="0.0.0.0" (
		call :setDHCP_Error "[IP_NULL_INPUT_ERROR]"
		exit
	)
	
	echo Please enter the Copier SUBNET in the following format 255.255.254.0
	echo.
	set /p "subnet=Enter SUBNET: " || set "subnet=0.0.0.0"
	echo.
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
			if !event_log_skip!==1 (
				goto :print_event_log
			) else (
				goto :validateIP
			)
		) else if "!t!"=="." (
			::set IPArr[!pCount!]=!g!
			set /a pCount=pCount+1
			set g=
		) else (
			set "g=!g!!t!"
			set IPArr[!pCount!]=!g!
		)
	)

:: The same as :splitIP but for the Subnet
:: Will split the Subnet into its octets and move the program along
:: If an octet size other than 3 (0-3) is detected, an error will be output

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

:: Same as :validateIP but for both IP and SUBNET entered by the user

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
:: This will 'build' the IP and SUBNET (entered or default) and use netsh to assign them

:changeIP
	set newIp=!IPArr[0]!.!IPArr[1]!.!IPArr[2]!.!IPArr[3]!
	set newSUBNET=!SUBNETArr[0]!.!SUBNETArr[1]!.!SUBNETArr[2]!.!SUBNETArr[3]!
	netsh interface ipv4 set address name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set subnet name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set address name="Ethernet" static %newIp% %newSUBNET% >nul 2>&1
	
	:: A ping timeout loop
	:: Will try pinging a max of 25 times, once a successful ping happens
	:: :cross_over_ready is called if not printing an event_log
	:: :print_event_log is called if printing an event_log
	
	:confirm_ping
		set attempt=0
		<nul set /p "=Crossing Over Now"
		:confirm_ping_loop
			<nul set /p "=."
			ping %newIp% -n 1 -w 1000 >nul 2>&1
			if %ERRORLEVEL%==0 (
				echo.
				echo.
				if %event_log%==0 (
					goto :cross_over_ready
					exit
				) else (
					goto :print_event_log
					exit
				)
			) else (
				set /a attemp+=1
				if %attempt%==25 (
					call :setDHCP_Error "[MAX_PING_ATTEMPT_ERROR]"
					exit
				)
				goto :confirm_ping_loop
			)
	
	:: Outputs that user can close window by pressing anything
	:: Opens the copiers EWS in defaulted browser
	
	:cross_over_ready
		echo Cross-over ready. Press any key to exit and open EWS...
		pause>nul | echo.
		start "" https://%ip%
		exit
	

:: This will print out a Kyocera Event Log on compatible devices
:: Will first check if the specified file "event_log.txt" exists
::    If not, it creates it and the directory if needed
:: Then checks if LPR (Line Printer Remote) is enabled on PC
::    If not, gives instructions on how to enable
:: Then uses the ping timeout loop to test if the copier/printer is reachable via ping
::    If not, calls :exit_error and displays error that LPR is enabled but cannot Ping Device
::    Mostly a check when event_log_skip=1 is used which bypasses first ping timeout loop

:print_event_log
	
	set newIp=!IPArr[0]!.!IPArr[1]!.!IPArr[2]!.!IPArr[3]!
	set "file_path=%USERPROFILE%\Documents\event_log.txt"
	set "dir_path=%USERPROFILE%\Documents"
	
	if not exist "%file_path%" (
		if not exist %dir_path% (
			mkdir %dir_path%
		)
		echo ^!R^!KCFG"ELOG";EXIT;>"%file_path%"
	
	where lpr >nul 2>&1
	
	if %ERRORLEVEL%==1 (
		echo.
		echo LPR is not enabled, please enable LPR...
		echo   Turn Windows Features On or Off ^>
		echo   Print and Document Services ^>
		echo   LPR Port Monitor ^>
		echo   Restart Device
		call :exit_Error "[LPR_NOT_ENABLED_ERROR]"
	) else (
	
		ping %newIP% -n 1 -w 1000 >nul 2>&1
		
		if %ERRORLEVEL%==1 (
			call :exit_Error "[LPR_NO_PING_ERROR]"
			exit
		)
		
		lpr -S %newIp% -P 9100 "%file_path%"
		<nul set /p "=Sending Event Log Command"
			for /l %%i in (1,1,4) do (
				<nul set /p "=."
				timeout /t 1 >nul
			)
			echo .
			timeout /t 1 >nul
	)
	
	echo Event Log should be printing. Press any key to exit...
	pause>nul | echo.
	exit

:exit_Error
	echo.
	echo %~1 Press any key to exit...
	pause>nul | echo.
	exit

:: This sets the ethernet settings back to DHCP and outputs a passed error code

:setDHCP_Error
	netsh interface ipv4 set address name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set subnet name="Ethernet" dhcp >nul 2>&1
	echo %~1 Press any key to exit...
	pause>nul | echo.
	exit
	
:: This sets IPv4 address and SUBNET back to DHCP
:: This will NOT output an error code and is a direct result of option 3 in MENU

:setDHCP
	netsh interface ipv4 set address name="Ethernet" dhcp >nul 2>&1
	netsh interface ipv4 set subnet name="Ethernet" dhcp >nul 2>&1
	
	<nul set /p "=Returning to DHCP"
		for /l %%i in (1,1,4) do (
			<nul set /p "=."
			timeout /t 1 >nul
		)
		echo .
		timeout /t 1 >nul
	
	echo Set IPv4 Settings back to DHCP. Press any key to exit...
	pause>nul | echo.
	exit

exit
