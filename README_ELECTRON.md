# TriggerFinder Desktop (Electron)

This package wraps your existing web UI into a desktop application using Electron.

## Requirements
- Node.js 18+ (recommended 20 LTS)
- npm

## Install
```bash
npm install
```

## Run (dev)
```bash
npm start
```

## Build Windows EXE (NSIS installer)
```bash
npm run dist
```
Output will be in `dist/`.

## Notes
- Your app is loaded from `public/index.html`.
- If you want a native folder picker button inside the UI, you can call:
  `window.desktop.pickFolder()` (exposed by `preload.js`).
