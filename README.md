# Crossover

![Batch](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue?logo=windows)
![Status](https://img.shields.io/badge/Status-Stable-brightgreen)
![Used in Production](https://img.shields.io/badge/Used%20in%20Production-Weekly-success)

**Author:** Zach Reid | [zforgehub.dev](https://zforgehub.dev)

---

## Overview

Crossover is a Windows batch script that automates the process of configuring a laptop's Ethernet adapter for direct crossover connections to copiers, printers, switches, routers, and other networked devices with static IP addresses.

Built out of a real frustration — manually navigating Windows network settings is slow, error-prone, and easy to get wrong at exactly the wrong moment. This script handles it in seconds with a simple CLI prompt.

Used weekly in the field by multiple copier service technicians. One colleague described it as one of the most useful tools he's used on the job.

---

## The Problem It Solves

When a field technician needs to connect directly to a device (crossing over), they have to manually change their laptop's Ethernet IPv4 settings to match the device's subnet — changing the last octet to avoid an IP conflict. It sounds simple, but in practice:

- It's easy to accidentally type the device's IP instead of adjusting the last octet
- The subnet mask is easy to forget, especially on non-standard networks
- Mistakes aren't obvious until you've closed all the settings dialogs and tried to load the device's web page — only to find it fails
- Then you have to open everything again and redo it

This script eliminates all of that. Enter the device's IP, and it handles the rest — matching the subnet, calculating a safe laptop IP, applying the settings, and verifying the connection with a ping check before reporting success.

---

## Features

- **Automatic IP calculation** — matches the device's subnet and sets the last octet to `.25` (or `.35` if the device is already on `.25`)
- **Input validation** — checks all octets are within valid range (0–255) before applying anything
- **Ping verification** — confirms network connectivity before reporting a successful crossover
- **Max retry limit** — 25 attempts before reporting a failed state, preventing infinite loops on bad input
- **DHCP restore** — one menu option to return the adapter back to automatic (DHCP) assignment
- **Error code reference** — built-in error code lookup for on-the-spot troubleshooting
- **PATH-friendly** — a stripped CLI version in `./PATH` can be added to your system PATH and called from any directory via CMD

---

## Menu Options

| Option | Description |
|---|---|
| 1 | Crossover using device IP — uses default subnet `255.255.255.0` |
| 2 | Crossover using device IP + custom subnet |
| 3 | Restore Ethernet adapter to DHCP |
| 4 | Display built-in error codes and troubleshooting reference |

---

## Usage Examples

**Standard crossover (Option 1):**
```
Device IP:  192.168.1.135
Laptop IP:  192.168.1.25  (subnet: 255.255.255.0)
```

**Last octet conflict handled automatically:**
```
Device IP:  192.168.1.25
Laptop IP:  192.168.1.35  (subnet: 255.255.255.0)
```

**Custom subnet (Option 2):**
```
Device IP:  192.168.1.25   Subnet: 255.255.254.0
Laptop IP:  192.168.1.35   Subnet: 255.255.254.0
```

---

## PATH Version

The script in `./PATH` is a stripped-down version designed to be placed in a custom Scripts folder added to your system PATH. It accepts all arguments via CLI without interactive prompts, allowing it to be called directly from CMD from any directory.

---

## Requirements

- Windows 10 or Windows 11
- Must be run with Administrator privileges (UAC prompt handled automatically)

> Windows 8.1 and earlier, macOS, and Linux are not supported and will not be added.

---

## Attribution

UAC elevation logic between the `:: -----` comment lines is credited to **Ben Gripka** and **dbenham** via [Stack Overflow](https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file).

---

## Status

Stable. Used in active field deployment on a weekly basis. Occasional fixes applied as edge cases are discovered. No major feature additions planned — it does exactly what it needs to do.

---

## Links

- 🌐 [zforgehub.dev](https://zforgehub.dev) — Portfolio & DevHub

