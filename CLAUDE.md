# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development (starts React + Electron in parallel)
npm run dev

# Transpile Electron main process only
npm run transpile:electron

# Type-check + Vite build (React)
npm run build

# Lint
npm run lint

# Production builds
npm run dist:mac    # macOS DMG (arm64)
npm run dist:win    # Windows NSIS + portable (x64)
npm run dist:linux  # Linux AppImage (x64)

# Clean build artifacts
npm run clean
```

The dev server runs on port 5123 (strict). When `NODE_ENV=development`, `NODE_TLS_REJECT_UNAUTHORIZED=0` is set in `resourceManager.ts` — this **must never reach production builds**.

## Architecture

This is an Electron + React + TypeScript desktop app. The process boundary is the core architectural concern.

### Three-process model

**Main process** (`src/electron/`)
- `main.ts` — app bootstrap, `BrowserWindow`, tray icon, IPC handler registration
- `resourceManager.ts` — all system data collection (`systeminformation`, `os`, `fs`), 1-second polling loop, report builder, API submission
- `preload.cts` — compiled as CommonJS (`.cts`), bridges main ↔ renderer with a channel whitelist
- `util.ts` — typed `ipcMainHandle` / `ipcWebContentsSend` wrappers + frame URL validation (prevents renderer spoofing)
- `pathResolver.ts` — resolves UI and preload paths for packaged vs. dev modes

**Renderer** (`src/ui/`)
- Single-page React app. Accesses system data only through `window.electron` — never directly via Node.js.
- `App.tsx` contains all UI: live stats bars, static device info cards, "Send To IT" button with `idle | sending | success | error` state.

**Shared types** (`types.d.ts` at root)
- `Statistics`, `StaticData`, `InfoFilesObject`, `EventPayloadMapping`, `Window["electron"]` — all global, no imports needed. Keep type changes here in sync across all three processes.

### IPC contract

| Direction | Channel | Payload |
|-----------|---------|---------|
| Renderer → Main (invoke) | `getStaticData` | none → `StaticData` |
| Renderer → Main (invoke) | `sendToIT` | `{ data: StaticData, stats: Statistics }` → `SendToITResponse` |
| Main → Renderer (push) | `statistics` | `Statistics` (every 1s) |

The preload whitelist (`VALID_INVOKE_CHANNELS`, `VALID_ON_CHANNELS`) and `validateEventFrame` in `util.ts` enforce that only the legitimate renderer window can trigger IPC.

### Info files

The app reads device metadata from flat `.txt` files:
- **Windows:** `C:/info/`
- **Mac/Linux:** `~/info/`

Files: `RCTag.txt`, `Department.txt`, `AssignedLocationBuilding.txt`, `AssignedLocationRoom.txt`, `LocalAccount.txt`, `OwnerFirstName.txt`, `OwnerLastName.txt`, `OwnerEmail.txt`, `UsageType.txt`, `YearModel.txt`

Missing files return empty strings — the UI renders `—` for empty values.

### Build pipeline

- Electron main/preload: `tsc --project src/electron/tsconfig.json` → outputs to `dist-electron/`
- React renderer: `vite build` → outputs to `dist-react/`
- Packaging: `electron-builder` reads `electron-builder.json`; `scripts/afterPack.cjs` runs post-pack
- The preload is compiled as `.cjs` (CommonJS) because Electron's `sandbox: true` requires it

### Environment variables

Three required at runtime (validated on startup in `resourceManager.ts`; missing any throws):

| Variable | Purpose |
|----------|---------|
| `PUBLIC_IP_ENDPOINT` | HTTPS endpoint returning the machine's public IP |
| `SEND_REPORT_ENDPOINT` | HTTPS endpoint to POST diagnostic reports |
| `AUTH_TOKEN` | Bearer token for both API calls |
