# RC System Dashboard - Backend Documentation

This document describes the internal architecture, data flow, and maintenance details for
future developers.

---

# System Architecture

The application is split into three layers:

## 1. Electron Main Process

Responsible for:

- system data collection
- IPC handling
- report submission
- network detection

## 2. React Renderer

Responsible for:

- UI rendering
- displaying system stats
- triggering IPC calls
- sending IT requests

## 3. Preload Script

Secure bridge between renderer and main process:

- exposes limited API
- prevents direct Node.js access in UI

---

# Data Flow

## Live System Stats

Function:
pullResources()

Runs every 3000ms and sends:

- CPU usage
- RAM usage
- Storage usage
- Network speeds

Sent via IPC event:
statistics

---

## Static System Data

Function:
getStaticData()

Collects:

- CPU model
- RAM size
- Disk size
- OS information
- Device identifiers
- User session info
- Network info

Also calls:
getFullNetworkData()

---

## Network Information

### Local IP

Extracted from OS network interfaces.

### Public IP

Fetched from:

GET https://blackstone.roanoke.edu:4434/scotty/itrelay/public/api/ip

Includes caching system:

- cachedPublicIp
- publicIpPromise

Prevents duplicate network requests.

---

# Report Generation

Function:
buildFullItReport()

Creates a formatted system report containing:

- Device info (manufacturer, model, serial, RC Tag)
- System info (computer name, OS, uptime)
- Owner info (name, email, department, location)
- Network info (MAC, local IP, public IP, speeds)
- Hardware snapshot (CPU, RAM, storage usage)

Newlines are replaced with `<br>` before transmission.

---

# Report Submission

Endpoint:
POST https://blackstone.roanoke.edu:4434/scotty/itrelay/public/api/email

Headers:
Content-Type: application/json

Payload:
{
  "auth_token": "<AUTH_TOKEN from .env>",
  "body": "<report with newlines replaced by <br>>",
  "code": "<user-entered code>"
}

---

# IPC Communication

## Renderer → Main

| Event         | Payload               |
| ------------- | --------------------- |
| getStaticData | none                  |
| sendToIT      | { data, stats, code } |

---

## Main → Renderer

| Event      | Payload                          |
| ---------- | -------------------------------- |
| statistics | CPU, RAM, storage, network stats |

---

# Info Files System

Reads from:

Windows: C:/info
Mac/Linux: ~/info

Files:

- RCTag.txt
- Department.txt
- AssignedLocationBuilding.txt
- AssignedLocationRoom.txt
- LocalAccount.txt
- OwnerFirstName.txt
- OwnerLastName.txt
- OwnerEmail.txt
- UsageType.txt
- YearModel.txt

Used for:

- asset tracking
- device identification
- IT reporting metadata

---

# Security Notes

## API Security

Authentication uses `auth_token` in the JSON request body.

Stored in `.env` as `AUTH_TOKEN` — bundled into the app via `extraResources` at build time.

## IPC Security

- `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`
- IPC channels are whitelisted in preload
- Frame URL validated on every IPC call

---

# Maintenance Notes

## If reports fail:

- check API availability
- verify token
- check network connectivity

## If public IP is missing:

- internal endpoint may be down
- fallback returns "N/A"

---
