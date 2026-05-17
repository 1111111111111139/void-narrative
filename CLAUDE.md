# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**VOID / NARRATIVE** — single-file Chinese-language AI-driven infinite-stream horror text game.  
File: `horror-game.html` (~7100 lines). No frameworks, no build tools, no dependencies.  
AI acts as Game Master: narrates environment, role-plays all NPCs, adjudicates rules, advances plot.

---

## Architecture: Page System

SPA with **3 bottom-tab views** + sub-pages + modals/panels:

| Tab | ID | Purpose |
|-----|-----|-----|
| **Story** | `page-story` | Chat engine: messages, combat bar, copy info panel |
| **Terminal** | `page-terminal` | 5 sub-panels: Home / Forum / Map / Attributes / Contacts |
| **Settings** | `page-settings` | Entry point → sub-pages for all config |

### Terminal Sub-Panels

| Panel | Key Functions |
|-------|--------------|
| **Home** | Survival points, countdown, rank, SAN+EQ visualization, location threat, nearby dungeons |
| **Forum** | 5 boards (intel/party/trade/will/chat), post/purchase/reply, AI auto-generation |
| **Map** | Dual-layer topology (regions → subNodes), breathing dot states, coded connection lines, go-to popup |
| **Attributes** | 4 stats (strength/agility/insight/calm) with pip bars and 500-point upgrade buttons |
| **Contacts** | Established-contact character list, online status, private chat entry |

### Sub-Pages (all `page-*`)

`profile`, `char-list`, `char-edit`, `world-presets`, `preset-edit`, `plots`, `lores`, `lore-edit`, `global-rules`, `saves`, `memories-view`, `about`, `rules`(rule reference), `private-chat`

### Overlays & Modals

`modal-api`, `modal-gift`, `modal-term-settings`, `modal-appearance`, `modal-forum-post`, `modal-masks`, `modal-mask-edit`, `modal-memory`, `dialog-confirm`, `goto-overlay`, `forum-post-overlay`, `user-panel-overlay`, `npc-info-overlay`, `char-info-overlay`, `copy-panel-overlay`, `death-overlay`, `intro-overlay`

---

## Data Layer: `Store` Object

**localStorage key**: `'VOID_V1'`

### Core Methods

| Method | Purpose |
|--------|---------|
| `Store.init(opts)` | Bootstrap: load from localStorage, run migrations, `_upgrade()` |
| `Store.save()` | Flush `_db` to localStorage. Call after every mutation. |
| `Store.player()` | Returns `_db.player` |
| `Store.messages()` / `Store.characters()` / `Store.inventory()` | Domain accessors |
| `Store.addMessage(msg)` | Add with auto-generated ID (`msg_timestamp_random4`) |
| `Store.plots()` / `Store.createPlot()` / `Store.switchPlot()` / `Store.deletePlot()` | Multi-plot archive system |
| `Store.lores(type?)` / `Store.addLore()` / `Store.updateLore()` / `Store.deleteLore()` | Lore library CRUD |
| `Store.presets()` / `Store.addPreset()` / `Store.setActivePreset()` | World presets |
| `Store.masks()` / `Store.activeMask()` / `Store.addMask()` / `Store.setActiveMask()` | Player masks |
| `Store.slots()` / `Store.saveToSlot()` / `Store.loadFromSlot()` | Save slots |
| `Store.exportJSON()` / `Store.exportFile()` / `Store.importJSON()` / `Store.resetAll()` | Data portability |
| `Store.apiCfg()` / `Store.memCfg()` / `Store.stateCfg()` | API config with `useMain` fallback |

### Data Model (full `_db` structure)

```
_db {
  version: 1,
  player: {
    name, voidId, identity, gender,
    san, maxSan, survivalPoints, plotTwist,
    points, rank, totalPlayers, nextDeduction,
    copiesCleared, voidDays, statusEffects: [],
    attributes: { strength, agility, insight, calm },  // 1-10 per stat
    killCount, killMark, monsterKills: {}
  },
  currentCopy: {
    name, type, difficulty, chapter,
    core, rules, discoveredRules: [],
    location, completionStatus, terminalInterference,
    mapRegions: [Region],   // dual-layer topology (replaced old mapNodes)
    quests: [], tideActive, stormActive, completed
  },
  messages: [ {id, type, content, characterName?, characterId?, timestamp, meta, pending?} ],
  characters: [{
    id, name, gender, affection, relation, present, persona, appearance, avatar,
    isNPC, npcType, isAutoCreated, memories: [], simpleMemories: [], tags: [],
    affectionEnabled, tabooEnabled, memoryEnabled, initiativeEnabled,
    contactAccepted, contactEstablished, contactRequested,
    isOnline, isAlive, deathCause, deathTime, lastSeenLocation, lastSeenTime,
    position, killCount, hasKillMark, san, points, rank, voidId,
    attributes: { strength, agility, insight, calm },   // auto-assigned on CHAR_JOIN
    inventory: [], survivalDays                           // auto-set on CHAR_JOIN
  }],
  inventory: [ {id, name, type, qty, usable, consumable, durability, tradeable, desc, effect} ],
  memories: {
    global: [Memory],       // no limit, importance ≥0.7, compress at ≥100
    npc: { [npcId]: [Memory] },  // max 20 per NPC, auto-discard oldest
    copy: { [copyName]: [Memory] },  // one record per copy, no limit
    character: { [charId]: [Memory] },  // no limit, compress at ≥50
    forum: [Memory]         // max 50, compress at ≥50
  },
  forumPosts: { intel:[], party:[], trade:[], will:[], chat:[] },
  privateChats: { [charId]: { messages:[], hasUnread } },
  settings: { api, memoryApi, stateApi, theme, fontSize, _lastAiForumPost },
  config: { activePresetId, activePlotIdx, activeMaskId },
  worldPresets: [Preset],
  plots: [Plot],
  lores: [Lore],
  masks: [Mask],
  saveSlots: [Slot],
  globalRules: [String],   // absolute prohibition rules
  skills: []
}
```

### Memory System: 6 Partitions

| Partition | Key | Limit | Compress | Injection Priority |
|-----------|-----|-------|----------|-------------------|
| Character | `memories.character[id]` | none | ≥50 → 3-5 summaries | 1 (highest) |
| Copy | `memories.copy[name]` | none | never | 2 |
| Global | `memories.global[]` | none | ≥100 (low-importance old) | 3 |
| Forum | `memories.forum[]` | 50 | ≥50 → summary | 4 |
| NPC | `memories.npc[id]` | 20/NPC | discard oldest | 5 (lowest) |

**Context injection**: ≤8 entries, ≤400 chars total.  
**Memory methods**: `Store.addGlobalMemory()`, `Store.addNPCMemory()`, `Store.addForumMemory()`, `Store.addCopyMemory()`, `Store.addCharMemory()`, `Store.globalMemories()`

### Map System: Dual-Layer Topology

```
mapRegions: [{
  id, name, threatLevel (safe/medium/high/fatal), state (current/visited/unknown),
  x, y (percentage), connections: [regionId],
  subNodes: [{
    id, name, type (location/dungeon/shortcut),
    state (current/visited/unknown), dungeonState (cleared/active/unknown),
    x, y, connections: [subNodeId]
  }]
}]
```

**6 preset regions**: 荒原·东段, 东墟, 南墟, 铁穹, 边界地带, 执念之海  
**Breathing dot states**: `dot-unknown`(red,2s) / `dot-active`(blue,1.5s) / `dot-cleared`(green,3s) / `dot-visited`(dark-blue,2.5s) / `dot-current`(white,0.8s)  
**Dungeon ring**: dashed circle (unknown) / solid (active) / solid+checkmark (cleared)  
**Line colors**: `line-cleared`(#2E7D32) / `line-active`(#3A6B8C) / `line-partial`(#8E2A2A dashed) / `line-unknown`(gray dashed)

---

## System Prompt Architecture (`buildSystemPrompt()`)

### Hierarchy (top to bottom in final prompt)

```
[全局雷区]                    ← ABSOLUTE TOP — filters all output
5-Tier Priority System        ← conflict resolution rules
AI Role Definition            ← narrator + NPC actor + system
Narrative Style Rules         ← 2nd-person, forbidden words, physiological reactions
NPC Play Rules                ← dialogue format, presence rules, NPC 3 types
Markers Syntax                ← 20+ marker types
Player Current State          ← SAN/points/location/inventory/memories
Active Character/NPC List     ← present characters with affection/persona
Copy Status                   ← current copy name/rules/location
World Preset                  ← VOID definition, generation rules, AI permissions
Monster System                ← 4 types, combat rules, kill rewards
Time System                   ← objective time, tides, storms
Item System                   ← 6 types, prohibitions, sources
Attributes & Judgment         ← 4 stats, probability formula
Character Interaction         ← initiative, background actions (6 categories)
Points System                 ← deduction, earning, ranking
World Geography               ← known areas, exploration, shortcuts
Copy System                   ← types, rules, difficulties, completion
SAN System                    ← triggers, recovery, 6 stages
Memory Compression Requests   ← triggered at partition limits
```

### Priority 5-Tier System

| Tier | Content | Rule |
|------|---------|------|
| **L1** | Global Rules > VOID Rules > Item Limits > Copy Fatal Rules | Highest — cannot be overridden |
| **L2** | User Input > Scene State > SAN/Points > Combat State | Drives narrative |
| **L3** | Character/NPC Cards > Affection > Memories > Background State | Shapes interaction |
| **L4** | World Presets > Region Threat > Time System > Terminal Interference | Sets world tone |
| **L5** | Forum Generation > Background Actions > Simulated Purchases | Background systems |

### AI Markers (20+ types, parsed by `AI.parseCommands()`)

| Marker | Purpose |
|--------|---------|
| `[SAN ±X]` | SAN change |
| `[AFFECTION name ±X]` | Affection change (Δ≥10 → auto-store to char memory) |
| `[ITEM +name:type]` / `[ITEM -name]` | Item gain/loss |
| `[QUEST name]` / `[QUEST_DONE name]` | Quest tracking |
| `[SCENE name]` / `[LEAVE name]` | Character entrance/exit |
| `[CHAR_JOIN name role days]` | New character (auto-assign attributes by survival days) |
| `[CHAR_UPDATE name field:value]` | Background character state update |
| `[MONSTER type:name]` | Monster encounter |
| `[MAP_NODE name:type:threat:regionId]` | Add map node |
| `[FORUM_POST board:title]` | AI forum post |
| `[MSG name:content]` | Character initiative message to user |
| `[CONTACT_REQ name]` | Contact request from character |
| `[MEMORY name importance:X]` | Memory extraction |
| `[MEMORY_COMPRESS type target]` | Memory compression |
| `[TIME +X]` | Time advancement |
| `[TIDE_START/END]` / `[STORM_START/END]` | Environmental events |
| `[COPY_END]` | Copy completion |

---

## JavaScript Architecture

### Global Objects (in execution order within `<script>`)

```
DEMO                  — static demo data (characters, forumPosts, messages)
DEFAULT_WORLD_PRESET  — default world configuration (VOID rules, mechanics, features)
DEFAULT_MAP_REGIONS   — 6-region dual-layer topology seed data
Store                 — data layer (lines ~2200-2700)
  ├── init/migrations/save
  ├── CRUD (messages/characters/inventory/items/skills)
  ├── Memory (global/npc/copy/character/forum adders)
  ├── Lore library, Masks, Save slots
  ├── API config accessors (main/memory/state with useMain fallback)
  ├── World presets CRUD
  └── Plot management (archive/restore pattern)
buildSystemPrompt()   — system prompt builder (lines ~2700-3100)
AI                    — AI module (lines ~3100-3600)
  ├── call/streamCall (OpenAI-compatible chat completions)
  ├── _buildMessages (context window assembly)
  ├── parseCommands/applyCommands (20+ marker types)
  ├── parseResponse (narrative/NPC dialogue segmentation)
  ├── testConnection (API connectivity check)
  ├── generateForumReplies (forum AI simulation)
  └── generateCharacters (character card generation)
App                   — main controller (lines ~3600-7100)
  ├── init/navigateTo/navigate back
  ├── Render: renderAll/renderMessages/renderCharacters/renderMap/renderForum/renderHome/renderAttributes/renderContacts
  ├── Map: _renderRegionMap/_renderRegionSubMap/_renderTopologyGraph/_enterRegion/_exitRegion/_getNodeStyle/_getLineClass
  ├── Terminal: switchTermTab/switchForumBoard
  ├── Forum: _openForumPostSheet/_submitForumPost/_openForumPost/_forumTick
  ├── Plot: renderPlotList/createPlotDialog
  ├── Lore: renderLoreList/openLoreEditor/saveLore/generateLoreChar
  ├── Character: renderCharList/openCharEditor/saveCharEditor
  ├── Masks: _openMaskManager/_openMaskEditor/_saveMask
  ├── Memory: renderMemViewer/_renderMemList/_setMemFilter
  ├── Profile: renderProfile/saveProfile
  ├── Settings: openSettingsItem/renderSaveSlots
  ├── Private Chat: _openPrivateChat/_closePrivateChat/_sendPrivateMsg
  ├── User Panel: openUserPanel/renderUserPanel/useItem/discardItem/_giftItem
  ├── Combat: _startCombat/_endCombat/_fleeCombat
  ├── SAN: applySanEffect/startSanJitter
  ├── Death: _triggerAssimilation/_triggerErasure/_deathRestart/_deathBacktrack
  ├── Events: bindEvents (all DOM event registration)
  └── Utilities: escapeHtml/formatContent/parseContent/closeModal
```

### API Integration

Three independent OpenAI-compatible API configs:

| Config | Key | Model | Purpose |
|--------|-----|-------|---------|
| Main | `settings.api` | `gpt-4o-mini` | Dialogue, character generation |
| Memory | `settings.memoryApi` | (falls back to Main) | Diary, memory extraction |
| State | `settings.stateApi` | (falls back to Main) | Reserved for rule adjudication |

`useMain: true` → falls back to Main API config. API base URL: `/chat/completions`.  
Streaming via SSE `ReadableStream`. Model list fetched from `/models`.

---

## CSS Architecture

All in `<style>` tag (lines ~10-1000). Key design patterns:

- **CSS Custom Properties** on `:root` and `body.light-theme` for theme switching
- **Key variables**: `--bg`, `--surface`, `--text`, `--text-2`, `--text-3`, `--accent`(#8E2A2A), `--border`, `--radius`, `--glass`
- **Glassmorphism**: `backdrop-filter: blur()` on dock, panels, modals, terminal topbar
- **Font stack**: `--font-serif`(Songti/SimSun) / `--font-ui`(SF Pro/PingFang) / `--font-mono`(SF Mono/Consolas)
- **Mobile-first**: max-width 430px, safe-area-inset, 100dvh
- **SAN effects**: 5 levels of jitter animation + red vignette box-shadow + text-shadow
- **Overlay system**: `.panel-overlay`(bottom sheet) / `.center-modal-overlay`(centered) / `.modal-overlay`(bottom)
- **Breathing dots**: 5 keyframe animations for map topology nodes
- **Theme transition**: `body.light-theme` swaps all `--bg/text/surface` variables

---

## Key Design Decisions

1. **Single file**: 7100-line `.html` — no build step, instant iteration
2. **Store as single source of truth**: never write to localStorage directly; always use `Store.save()`
3. **Plot archive/restore pattern**: `_archiveActivePlot()` deep-clones current copy into plot array; `_loadPlot()` restores
4. **CHAR_JOIN auto-attributes**: survival days → attribute total range → random distribution ≤8 per stat
5. **NPC/Role distinction**: `isNPC` flag drives affection, memory, contact behavior
6. **Memory 6-partition with priority injection**: character > copy > global ≥0.8 > forum > npc; ≤8 entries / ≤400 chars
7. **MapRegion dual-layer**: regions (click → zoom) / subNodes (click → go-to popup); coordinates in percentage
8. **Death single-backtrack**: `_hasBacktracked` prevents more than one resurrection
9. **System Prompt hierarchy**: global rules at absolute top; 5-tier priority; markers parsed post-response
10. **Streaming AI**: SSE `ReadableStream` with real-time bubble update via `_updateStreamBubble()`

---

## File Line Map (approximate)

| Lines | Section |
|-------|---------|
| 1-8 | `<!DOCTYPE html>` → `<title>` |
| 9-1000 | `<style>` — all CSS |
| 1000-2100 | `<body>` — all HTML |
| 2100-2200 | `DEMO` static data |
| 2200-2300 | `DEFAULT_WORLD_PRESET` + `DEFAULT_MAP_REGIONS` |
| 2300-2700 | `Store` — data layer |
| 2700-3100 | `buildSystemPrompt()` — system prompt builder |
| 3100-3600 | `AI` — AI module |
| 3600-7100 | `App` — main controller |
| 7100-7130 | Bootstrap + `</script></body></html>` |
