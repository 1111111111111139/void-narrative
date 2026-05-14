# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**VOID / NARRATIVE** — a single-file Chinese-language infinite-stream horror text game. The app lives in `horror-game.html` (~2100 lines): CSS, HTML, and vanilla JS. No build tools, no frameworks, no dependencies. Open `horror-game.html` directly in a browser. AI serves as the game master, narrating the environment, role-playing all NPCs, adjudicating rules, and advancing the plot.

## Architecture

The app is a single-page application with four bottom-tab views:

| Tab | ID | Purpose |
|-----|-----|-----|
| 剧情 (Plot) | `view-plot` | Plot archive list + creation flow |
| 设定 (Lore) | `view-lore` | Lore library — worlds, local settings, character cards, storylines |
| 记忆 (Mem) | `view-mem` | Cross-plot memory browser with search/filter |
| 我 (Me) | `view-me` | User center — API config, persona masks, data export/import |

## Data Layer (`Store` object, line ~1821)

All data persisted in `localStorage` under key `SN_V2`. The `Store` object is the single source of truth — never write to localStorage directly.

- **`Store._db`** — in-memory copy of the full database. Always access via helper methods.
- **`Store.init()`** — called once at bootstrap. Loads from localStorage, handles V1 migration, runs `_upgrade()`.
- **`Store.save()`** — flushes `_db` to localStorage. Must be called after any mutation.

### Data Model

```
_db {
  version, config: { api, memoryApi, stateApi, activeMaskId },
  masks: [{ id, name, bio, avatar, traits }],
  lores: [{ id, title, type, keywords, content, systemConfig?, avatar?, bio?, ... }],
  plots: [{ id, globalId, charIds[], name, chats[], state, worldState, summaries[], starredThoughts[], ... }],
  globalMemory: { core[], summaries[] }
}
```

- **Lore types**: `global` (大世界), `local` (局部设定), `char` (角色卡), `storyline` (故事线)
- **Plots** reference lores by `globalId` and `charIds[]`. Each plot has `state` (affection, emotion, location) and `worldState` (quests, system memory, plot nodes).

### Key Store methods

`Store.lores(type?)` — all lores or filtered by type  
`Store.lore(id)` — single lore by id  
`Store.plots()` — all plot archives  
`Store.plot(idx)` — plot by array index  
`Store.addLore(data)` / `updateLore(id, data)` / `deleteLore(id)`  
`Store.addPlot(data)` / `updatePlot(idx, data)` / `deletePlot(idx)`  
`Store.exportJSON()` / `Store.exportFile()` / `Store.importJSON(json)`  
`Store.apiCfg()` / `Store.memCfg()` / `Store.stateCfg()` — typed API config accessors

## Key JavaScript Modules (all in global scope)

- **`WorldPresets`** (line ~1973) — World preset selector overlay. Used by both PlotFlow (create mode) and LoreCenter (lore mode). Manages system config (system assistant style, tone, call command) and time settings.
- **`PlotFlow`** (line ~2462) — Plot creation flow: select world → choose/generate character → create plot. Wires to `ChatEngine.enter()` on plot selection.
- **`LoreCenter`** (line ~2730) — Lore library CRUD. Handles `global`/`local`/`char`/`storyline` filters. Opens a full-page editor overlay for each lore type.
- **`CharEditor`** (line ~3073) — Character card editor (avatar, bio, keywords, sliders, AI-assisted parsing from text input).
- **`ChatEngine`** (line ~3523) — The dialogue engine. Renders chat flow with multi-character bubbles, handles system call (`@`), affection display, time/quest panels, diary generation, archive settings (auto-extract memory). Uses OpenAI-compatible API (`/chat/completions`).
- **`MePage`** (line ~4700) — User center: API key/URL config for main/memory/state APIs, mask management, data export/import/reset.
- **`MemViewer`** (line ~5050) — Memory viewer for the active plot. Aggregates core memories, raw chats, plot nodes, summaries, and system messages. Search and filter by type.
- **`Dialog`** (line ~2713) — Simple confirm/cancel modal utility.

## LLM Integration

Three separate API configs (all OpenAI-compatible chat completions):
- **Main API** (`config.api`) — dialogue, character generation
- **Memory API** (`config.memoryApi`) — diary generation, memory extraction
- **State API** (`config.stateApi`) — reserved

API calls use `fetch(url + '/chat/completions', ...)` with Bearer auth.

## CSS

All styles are embedded in `<style>`. Uses CSS custom properties on `:root` and `body.dark` for theming. Key variables: `--bg`, `--surface`, `--text`, `--text-2`, `--accent`, `--border`, `--radius`. Glassmorphism aesthetic via `backdrop-filter: blur()`.

Mobile-first with max-width 480px on larger screens. Custom overlays for modals, editors, and panels (no `<dialog>` usage).
