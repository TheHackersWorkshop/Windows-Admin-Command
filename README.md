# Windows Admin Command Center

A PowerShell-based management CLI for Active Directory administration, designed to standardize common tasks and ensure all actions are logged and confirmed before execution.

## Overview
This tool provides a menu-driven interface over common Active Directory operations. It is built to reduce repetitive command entry, improve consistency, and add basic safeguards around administrative actions.

## Key Features
- **Audit-Grade Logging:** All actions (success and failure) are timestamped and written to a local log file.
- **State-Based Workflow:** Select a target user or computer once, then perform multiple actions without re-entering identifiers.
- **Confirmation Prompts:** Actions like account changes, restarts, and OU moves require explicit confirmation.
- **Resilient Error Handling:** Try/catch handling prevents script crashes and returns useful error messages when objects are not found.
- **Admin Toolbox:** Includes common remote actions such as gpupdate /force and system restarts.

## Functionality
### User Management
- Retrieve detailed user properties (lockout status, group membership, password info)
- Enable/disable accounts
- Move users between OUs

### Computer Management
- View system and network details
- Trigger remote updates and restarts
- Enable/disable or move computer objects

## Project Structure
- Automatic creation of log directories in the user profile.
- Separate logic for User, Computer, and Action headers/functions for easy extensibility.

## Requirements
- PowerShell 5.1 or PowerShell 7+
- ActiveDirectory module
- Appropriate administrative privileges

---
*Developed as part of a proactive infrastructure management suite for high-availability enterprise environments.*
