@echo off
set version=3.2.2a
title IPv4 Copier Cross-Over by Zach (v%version%)

:: Please see original crossover.bat for full comments
:: This is meant to be ran from CLI when added to PATH
:: This will not prompt user for anything, meaning everything will need to be passed

if not "%1"=="am_admin" (
    powershell -Command "Start-Process -FilePath '%0' -ArgumentList 'am_admin %*' -Verb RunAs"
    exit /b
)

setlocal EnableExtensions
setlocal EnableDelayedExpansion

color B
echo.

set IPArr=[]
set SUBNETArr[0]=255
set SUBNETArr[1]=255
set SUBNETArr[2]=255
set SUBNETArr[3]=0
set /a pCount=0

set "ip_address=%2"
set "subnet=%3"

if "%subnet%"=="" (
    if not "%ip_address%"=="" (
        if "%ip_address%"=="--dhcp" (
            goto :setDHCP
            exit
        )
        if "%ip_address%"=="--debug" (
            goto :printErrorCodes
            exit
        )
        if "%ip_address%"=="--update" (
            start "" https://github.com/zachreid-96/Cross-Over
            exit
        )
        call :splitIP !ip_address! !subnet!
        pause>nul
        exit
    )
)

if not "%subnet%"=="" (
    if not "%ip_address%"=="" (
        call :splitIP !ip_address! !subnet!
        pause>nul
        exit
    )
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

::%arg_1% == ip_address | %arg_2% == subnet
:splitIP
    set local_ip=%~1
    set local_subnet=%~2
	set g=
	for /l %%i in (0,1,20) do (
		if !pCount! geq 4 (
			call :setDHCP_Error "[IP_EXCESS_OCTET_ERROR]"
		)
		set t=!local_ip:~%%i,1!
		if "!t!"=="" (
			if !pCount! neq 3 call :setDHCP_Error "[IP_MISSING_OCTET_ERROR]"
			if "%~2"=="" call :validate !local_ip! !local_subnet!
			call :splitSUBNET !local_ip! !local_subnet!
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
    set pCount=0
    set local_ip=%~1
    set local_subnet=%~2
    set SUBNETArr=[]
    set g=
    for /l %%i in (0,1,20) do (
    	if !pCount! gtr 3 (
    		call :setDHCP_Error "[SUBNET_EXCESS_OCTET_ERROR]"
    	)
    	set t=!local_subnet:~%%i,1!
    	if "!t!"=="" (
    		if !pCount! neq 3 call :setDHCP_Error "[SUBNET_MISSING_OCTET_ERROR]"
    		goto :validate !local_ip! !local_subnet!
    	) else if "!t!"=="." (
    		::set IPArr[!pCount!]=!g!
    		set /a pCount=pCount+1
    		set g=
    	) else (
    		set "g=!g!!t!"
    		set SUBNETArr[!pCount!]=!g!
    	)
    )
    echo Press any key to exit...
    pause>nul | echo.
    exit

:validate

    set local_ip=%~1
    set local_subnet=%~2

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

	set "valid_octets=0 128 192 224 240 248 252 254 255 "
    for %%0 in (!SUBNETArr[0]! !SUBNETArr[1]! !SUBNETArr[2]! !SUBNETArr[3]!) do (
        set "octet=%%0"
        for /f "tokens=*" %%A in ("!octet!") do set "octet=%%A"
            echo !valid_octets! | findstr /c:"!octet!" >nul || call :setDHCP_Error "[SUBNET_INVALID_OCTET_ERROR]"

	call :changeIP !local_ip! !local_subnet!
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
			timeout /t 1 >nul
			if %ERRORLEVEL%==0 (
				echo.
				echo.
			) else (
				set /a attempt+=1
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

echo Press any key to exit...
pause>nul | echo.
exit