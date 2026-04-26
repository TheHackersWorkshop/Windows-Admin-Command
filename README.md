# Windows Admin Command Center (Audit-Grade) v1.0

A professional-grade PowerShell management CLI designed for Active Directory administration. This tool provides a structured, audited environment for managing Users and Computers, ensuring that all administrative actions are logged and confirmed before execution.

## Overview
The **Windows Admin Command Center** was built with a "Safety-First" philosophy. It abstracts complex Active Directory cmdlets into a simple, menu-driven interface, making it ideal for Tier II/III administrators who need to perform repetitive tasks with surgical precision and accountability.

## Key Features
- **Audit-Grade Logging:** Every action (successful or failed) is timestamped and logged to a local file for compliance and troubleshooting.
- **State-Based Workflow:** Select a "Target User" or "Target Computer" and perform multiple operations without re-entering credentials or names.
- **Safety Confirmations:** Critical actions (Enabling/Disabling accounts, Restarts, OU Moves) require explicit 'Y/N' confirmation.
- **Resilient Error Handling:** Comprehensive `try/catch` blocks prevent script crashes and provide meaningful feedback when AD objects aren't found.
- **Admin Toolbox:** Quick access to common remote tasks like `gpupdate /force` and remote restarts.

## Functionality
### User Management
- **Lookup:** Safely retrieve deep property sets (`PasswordLastSet`, `LockedOut`, `MemberOf`, etc.).
- **Account Control:** Toggle account status (Enable/Disable) with a single command.
- **Organization:** Move users between Organizational Units (OUs).

### Computer Management
- **Infrastructure Audit:** View OS details, IP addresses, and last logon dates.
- **Remote Actions:** Execute Group Policy updates and force restarts on remote workstations.
- **Inventory Control:** Enable, disable, or relocate computer objects within AD.

## Project Structure
- **Global Logging:** Automatic creation of log directories in the user profile.
- **Modular Design:** Separate logic for User, Computer, and Action headers/functions for easy extensibility.

## Requirements
- Windows PowerShell 5.1 or PowerShell 7+
- **ActiveDirectory** PowerShell Module
- Local or Domain Admin privileges (appropriate for the target environment)

---
*Developed as part of a proactive infrastructure management suite for high-availability enterprise environments.*
