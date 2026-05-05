# PowerShell SysAdmin Toolkit
### Ported from Linux-Native Utilities

A collection of high-performance PowerShell scripts designed to mirror the functionality of my Linux networking and system administration tools. This toolkit is built for speed, transparency, and deep-system visibility in Windows environments.

## Repository Overview

This repo contains a suite of PowerShell (`.ps1`) scripts that replace or enhance traditional Windows administrative tasks with a Linux-inspired workflow.

| Script | Functionality | Linux Equivalent / Inspiration |
| :--- | :--- | :--- |
| **Admin.ps1** | Centralized Command Center for elevated system tasks. | `sudo` / `root` dashboard |
| **DNS_Check.ps1** | Advanced DNS resolution and propagation testing. | `dig` / `nslookup` |
| **Dump.ps1** | System state capturing and log exporting. | `dmesg` / `journalctl` |
| **Net.ps1** | Network interface monitoring and socket analysis. | `netstat` / `ip addr` |
| **Ntools.ps1** | Network diagnostic utility suite. | `nmap` (basic) / `traceroute` |
| **ssh_copy.ps1** | Automated SSH key distribution and management. | `ssh-copy-id` |

## Key Features

* **Elevated Workflow:** `Admin.ps1` acts as a primary entry point for managing system-level changes without hunting through the GUI.
* **Networking Parity:** Scripts like `Net.ps1` and `DNS_Check.ps1` provide the granular output typically found in terminal-heavy Linux environments.
* **Automation-Ready:** All tools are designed to be lightweight, portable, and easily integrated into larger automation pipelines or remote management sessions.

## Usage

To use these tools, ensure your [Execution Policy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy) allows for local script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
