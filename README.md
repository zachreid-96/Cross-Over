# Cross-Over
A simple cross-over batch script for Copiers, Printers, Switches and the like.

This project started off because I found that manually changing the Ethernet adapter settings a little tedious. I would often accidentally type in the copier's IP address instead of changing the last octect, or I would forget the Subnet. I wouldn't realize I made a mistake until I had closed all the settings and tried to open the copier's web page. Which failed. I would then waste more time opening the settings again and redoing them.

This script was developed for Windows 10/11 machines. Will not work on other OS's and support for Windows 8.1 and prior, Mac, or any Linux distro will not be added.

I find using this script easy and pretty fast. I built in some checks to make sure IP/Subnet octets are within a valid range (0-255). I then match the copiers octets, changing the last octet to xxx.xxx.xxx.25, and use that as the IP assignment for the laptop. Unless the copiers last octet is xxx.xxx.xxx.25, then the laptop will be xxx.xxx.xxx.35.

This can be used for a handful of things, crossing over to copiers, printers, gateways, routers, switches, anything really that has a static IP assigned and allows data transfer between an ethernet cable.

Before displaying a successful cross over message, a ping timeout will occur to ensure network is active on both PC and machine. In case of bad IP entered, a max of 15 tries is alloted and results in a failed state.

This script has a menu that gets outputed for the user. Below is a description of what each option does.
1) Prompts the user for the copier's IP address and will change the IPv4 Ethernet assignments to allow cross-over to a copier. This option utilizes the default subnet of 255.255.255.0
<br/> &emsp; Copier IP: 192.168.1.135 -> Laptop IP: 192.168.1.25 using 255.255.255.0 as Subnet
2) Prompts the user for the copier's IP address, then prompts the user for the copier's Subnet
<br/> &emsp; Copier IP: 192.168.1.25 Subnet: 255.255.254.12 -> Laptop IP: 192.168.1.35 Subnet: 255.255.254.12
3) This will set the laptop's Ethernet assignments back to DHCP
4) This will output the pre-programmed error codes, descriptions, and some examples. To be used for troubleshooting purposes.
5) Option to cross over and print Event Log on Kyocera models.
6) Option to print Event Log on older Kyocera models if already crossed over.
99) This will bring the user to the Github main page of this project to check for a new version update. (not output in menu)

I put it in the comments of the script, but I will reiterate it here. I thank Ben Gripka and dbenham over at https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file for the code between the :: ------------------------------------- lines. I am not skilled enough to come up with prompting for the Admin UAC on my own.

Feel free to use this as needed.
