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
| **Map** | Dual-layer topology (7 preset regions + AI expansion), clue-based unlock, breathing dot states, coded connection lines, centered go-to modal with copy history |
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
| `Store.apiCfg()` | API config accessor |

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
    background, personalGoal, fears: [],  // AI-auto-generated on CHAR_JOIN
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
  settings: { api, theme, fontSize, _lastAiForumPost },
  config: { activePresetId, activePlotIdx, activeMaskId },
  worldPresets: [Preset],
  plots: [Plot],
  lores: [Lore],
  masks: [Mask],
  saveSlots: [Slot],
  globalRules: [String]   // absolute prohibition rules
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

**7 preset regions**: 废城·旧区, 荒原·东段, 东墟, 南墟, 铁穹, 边界地带, 执念之海  
**Breathing dot states**: `dot-unknown`(red,2s) / `dot-active`(blue,1.5s) / `dot-cleared`(green,3s) / `dot-visited`(dark-blue,2.5s) / `dot-current`(white,0.8s)  
**Dungeon ring**: dashed circle (unknown) / solid (active) / solid+checkmark (cleared)  
**Line colors**: `line-cleared`(#2E7D32) / `line-active`(#3A6B8C) / `line-partial`(#8E2A2A dashed) / `line-unknown`(gray dashed)

---

## Game Design: World & Systems

### 地图与世界系统

**世界观**：VOID是高维文明建造的灵魂筛选器，是无限延伸的黑暗精神世界。玩家无实体，一切伤害体现为SAN值下降。已知地图只是冰山一角，随游戏推进无限扩展。

**大区域**：
- 7个预设大区域（废城·旧区/荒原·东段/东墟/南墟/铁穹/边界地带/执念之海），AI可扩展新区域
- 每个大区域包含3-5个小区域
- 初始2个大区域（废城·旧区、荒原·东段）默认可探索，无需线索
- 其余大区域需5条以上线索解锁，所需线索数与初始地距离成正比
- 7个预设区域探索完后AI自动扩展新区域，必须符合底层规则：所有区域必须是被执念污染的扭曲空间，不存在"正常"的地方

**小区域**：
- 每个大区域含3-5个小区域
- 解锁需1-3条线索，来源包括：论坛信息、角色对话、自主探索、副本线索
- 玩家在终端地图手动解锁
- 小区域间步行1-6小时，敏捷属性可缩短时间
- 跨大区域移动按天计算

**预设区域列表（7个）**：

1. **废城·旧区**（默认出生点）— 威胁：中等。腐烂的城市投影，执念密度适中，新手友好。小区域：旧街区（出生点）/地下商场/废弃医院/车站广场。遭遇概率：角色40%/NPC20%/怪物20%/无事件20%。

2. **荒原·东段** — 威胁：安全至中等。干裂的灰土荒野，空旷压抑，偶有微弱冷光。遭遇概率：角色30%/NPC15%/怪物20%/无事件35%。

3. **东墟** — 威胁：中等。废弃工业区残骸，执念污染明显，副本密度增加。遭遇概率：角色25%/NPC20%/怪物30%/无事件25%。

4. **南墟** — 威胁：中等至高。沉没的居民区，时间感扭曲，NPC密度高且行为异常。遭遇概率：角色20%/NPC30%/怪物35%/无事件15%。

5. **铁穹** — 威胁：高。巨型工业构造体内部，空间法则开始失效，精英怪物频繁。遭遇概率：角色15%/NPC20%/怪物45%/无事件20%。

6. **边界地带** — 威胁：致命。已知区域的尽头，物理法则严重扭曲，极少数轮回者到达过。遭遇概率：角色10%/NPC15%/怪物60%/无事件15%。

7. **执念之海** — 威胁：致命。纯粹的执念聚合体，接近即被侵蚀，无游荡者只有执念碎片。遭遇概率：角色5%/NPC10%/怪物75%/无事件10%。

废城·旧区和荒原·东段默认可探索，无需线索。其余5个大区域需5条以上线索解锁。

**移动逻辑**：
- 移动消耗游戏时间，同步消耗SAN
- 移动SAN消耗公式：意志1=每小时5SAN，每+1意志减少0.5SAN。意志10=每小时0.5SAN
- 后台自然消耗：每周期2-5SAN，与移动叠加计算
- 移动途中随机事件触发概率随距离和时间增加
- 移动中途遇到随机事件由旁白告知，玩家选择是否参与

**跨区域随机事件**：
- 类型：遇见熟人/陌生人（可沟通、交易、组队）、遭遇怪物（扣SAN）、神秘威胁
- 不直接导致死亡，属于奇遇性质
- 触发时旁白告知，玩家选择是否参与

### 副本系统

- 每个小区域含5-10个以上副本，难度根据所在大区域基础难度随机生成
- 初始区域默认难度低，兼作新手教程
- 通关后作为里程碑永久记录，不重置
- 进入副本期间难以移动，离开小区域则副本判定失败
- 通关副本可获传送奖励：由副本执念指向决定目标地点，不可跨度过大
- 副本难度等级：C级/B级/A级/S级。难度不固定——未被处理的副本随时间自动升级
- 终端干扰随副本等级增加：C级轻微延迟 → B级通讯不稳定 → A级论坛/地图瘫痪 → S级几乎瘫痪（仅显示基础状态）

### 副本《永乐园》设定

**基础信息**：B级 · 多人社交博弈+生存探索 · 3-5人 · 执念主体：精神科医生（伪装成小丑）· 执念核心："恐惧是可以被治愈的，只要你直面它" · 评分上限S · 首通+50%积分

**背景**：一座在VOID里持续运转的废弃游乐场。建造者是一名被无数恐惧症患者逼到极限的精神科医生，建造这座乐园强迫患者直面恐惧以达到治愈。他死后执念让游乐场继续运转，治愈变成了永无止境的折磨。医生伪装成小丑在园区游荡，不知道自己已经死了，仍在观察记录下一个病人。NPC依靠副本执念活着，以看玩家痛苦为乐，极少数保留部分人性，玩家无法轻易分辨。

**入场问卷**（入口处小丑递上，AI根据回答判断玩家恐惧点）：①喜欢哪种天气出行（晴/阴/雨）②独自一人时通常在做什么 ③上一次感到非常放松是什么时候、在哪里 ④更愿意待在哪里（宽阔广场/安静小房间）⑤有没有特别不喜欢但说不清原因的事物。填写=免费入场，AI判断恐惧点对应区域被同化者针对该玩家。不填写=SAN-15，针对性降低折磨随机化。故意填错可迷惑医生。

**副本规则（5条，仅2条为真）**：①把你觉得下一个病重的人推进手术室（真）②别让医生发现你的恐惧（真）③不要进入白色建筑（误导）④听到音乐停止时立刻蹲下（干扰）⑤保持队伍不分散（误导）

**园区区域**：入口广场（小丑游荡+售货机含精神药物/病历碎片/镇静剂，镇静剂可暂时抑制恐惧点触发）· 摩天轮区（舱底透明恐高被同化者在顶端，路过SAN-3恐高额外-5，安全带是医院约束带）· 鬼屋区（幽闭恐惧被同化者循环，内部真实手术刀器官标本，进入SAN-5出口是手术室走廊）· 过山车区（咳疾被同化者，座椅由轮椅改装安全扣是医疗约束扣，观看SAN-2）· 旋转木马区（最平静区域，木马由轮椅改装中心柱刻"第一批患者全部治愈"，SAN-1）· 白色建筑/手术室（唯一与主题不符的建筑，内部完整手术室进入SAN-8，医生在此恢复白大褂，手术台即处刑台）

**医生（小丑）**：小丑装扮但动作语言是医生的，游荡全园观察玩家。进入手术室后恢复白大褂身份自然揭露。无法被击杀，强行攻击游乐场愤怒所有NPC攻击性提升。不知道自己是答案，也不知道自己已死。

**人性考验**：无内鬼机制，副本内杀人合法。击杀其他玩家可夺取其积分，SAN-30+永久击杀标记，游乐场对击杀者短暂降低NPC攻击性。

**通关流程**：①入场填问卷游乐场针对性布置 ②探索各区域发现违和细节 ③任意玩家进入白色建筑副本进入倒计时NPC攻击性逐渐提升 ④玩家判断"最病重的人"将其推进手术室 ⑤推入医生→执念崩溃副本通关 ⑥推入其他玩家→该玩家被吞噬副本继续

**评分标准**：通关50% · 体验每个游乐设施+10% · 收集线索/违和细节每条+5% · 推入正确的人+20% · 副本内击杀不扣完成度但写入个人记录。S≥90% / A 70-89% / B 50-69% / C 通关不足50%

### 副本《缝合》设定

**基础信息**：C级 · 1-2人 · 无执念主体（VOID自然生长产物）· 场景：废弃商场 · 评分上限A · 首通+50%积分

**背景**：副本不是任何人的执念凝结，是VOID自然生长的产物。一座永续营业的商场，灯光音乐广播一切如常，但商品是排列整齐的人体肢体。顾客正常挑选、佩戴、食用。导购制服整洁负责入场仪式，为玩家佩戴面具后消失，副本结束前玩家不知道面具是别人的脸皮缝在自己脸上。

**双人机制**：双人进入时两人各自独立完成入场仪式，各自获得专属面具。副本内两人可自由行动（同行或分开），各自的面具和恐惧体验独立。通关时各自穿上导购递来的人皮离开。评分独立计算，一人触发顾客攻击不影响另一人评分。

**副本规则（3条）**：①请全程佩戴您的专属面具 ②本商场客流量较大，请跟随人流有序参观 ③看到出口请告知工作人员。商场内所有显眼位置有红字标识「相信规则！」，每件商品吊牌上也有同样字样。

**关键节点**：试衣间（镜子照出面具是脸皮，SAN-10）· 摘下面具（顾客缓慢转头包围，持续压缩空间，重新戴好面具后顾客散开）· 出口（多个出口均无法开启，走到任意出口门前广播播报"请告知工作人员"）· 通关（回到入口处导购手持人皮登场，穿上人皮后正门开启副本结束）

**SAN消耗**：入场见商品-5 · 第一次见顾客行为-5 · 试衣间镜子-10 · 摘面具后持续-3到-5每轮 · 被顾客包围攻击-3到-8每轮 · 见导购拿人皮-8 · 穿上人皮-10

**评分**：遵守所有规则未进试衣间未摘面具正常通关=A · 进过试衣间或摘过面具但最终通关=B · 触发过顾客攻击评分上限C

### SAN值系统

**消耗**：
- 移动消耗：意志1=每小时5SAN，意志每+1减少0.5SAN
- 后台自然消耗：每周期2-5SAN
- 战斗消耗：3-8SAN
- 进入副本消耗：5-10SAN
- 恐怖场景：3-15SAN
- 目睹好感度≥31的角色死亡：额外扣除SAN 10-20
- 目睹好感度≥61的角色死亡：额外扣除SAN 20-35
- 目睹好感度≥81的角色死亡：额外扣除SAN 25-40
- 目睹好感度≥91（恋爱对象）的角色死亡：额外扣除SAN 20（叠加在档位扣除之上）
- 好感度越高扣除越多，由AI根据具体情况判定

**恢复途径**：
- 通关副本奖励：+10~+30SAN
- 药剂注射：+5~+15SAN（来源：副本奖励或论坛交易）
- SAN<30时角色优先使用携带的药剂/食物自救；无道具时优先逃离副本或向安全区移动

**归零后果**：SAN归零触发被同化事件，玩家不再是轮回者。

### 积分系统

- 每24小时扣除100积分（基于VOID大世界时间）
- 扣除前1小时终端提醒，前10分钟持续警告文字变红
- 积分<200标注低，<100持续警告，=0无法支付下次扣除，变负则抹杀
- 获取途径：通关副本、击杀怪物、论坛帖子被购买

### 死亡条件（仅两种）

- **积分变负**：直接抹杀
- **SAN归零**：被同化

### 击杀轮回者

- 继承被击杀者全部积分
- 击杀者SAN下降当前值30-50%（根据被击杀者挣扎程度）
- 好感度记录保留不重置
- 获得永久击杀标记（hasKillMark=true），被孤立或猎杀风险增加

### 组队

- 队伍上限2人，发起邀请对方终端收到弹窗确认
- 超出副本人数的位置由AI角色自动补位
- 队伍和独行SAN消耗完全相同，各自独立扣除，无减免也无叠加
- 目睹队友死亡适用目睹死亡额外扣除规则

### 好感度系统

**基础档位**：
- ≥1：可交易
- ≥31：通讯可建立，主动性触发，目睹死亡额外SAN-10~20
- ≥61：日常问候偶尔触发，目睹死亡额外SAN-20~35
- ≥81：深度信任——危险时优先保护玩家，目睹死亡额外SAN-25~40
- ≥91：解锁亲密关系——可触发表白/被表白事件

**亲密关系**：
- 表白/被表白/分手均触发独立小弹窗（终端通讯界面），有接受/拒绝选项
- 拒绝后好感度-10，冷却期由AI根据双方性格和当前状态判定
- 恋爱状态效果：通讯录特殊标记（♥），好感度掉落阈值提高（日常摩擦不轻易掉好感），副本内主动挡伤害，目睹玩家死亡SAN额外-20（叠加在档位扣除之上）
- 支持同性关系，AI根据角色背景和互动历史自然推进

**分手机制**：
- 三种触发方式：玩家主动提出、角色主动提出（好感度持续下降至阈值以下或触发特定事件）、对方死亡
- 分手事件写入 `memories.character[id]`，重要性 0.9
- 分手后可正常复合，需好感度重新积累至≥91且AI判定时机合适

**背叛惩罚**：
- 击杀或出卖恋爱对象：好感度归零，SAN-50，永久记录在 `memories.character[id]`
- 被背叛方（如存活）对该角色好感度直接降至-100

### 多人副本角色行为规则

每个轮回者在副本内都有自己的利益考量，AI控制的角色会根据以下因素自主判断是否合作或背叛，不会无条件配合玩家：

- **积分状态**：积分低于300的角色更容易铤而走险，做出激进选择（如抢先夺取关键道具、隐瞒出口位置、在资源紧缺时拒绝分享）
- **好感度**：对玩家好感度低于0的角色戒心更高，不会主动分享关键信息；好感度高于50的角色更倾向于合作，但仍可能因自身生存压力而保留部分信息
- **性格标签**：谨慎型角色不轻易暴露立场，倾向于观察后再行动；冲动型角色更容易提前行动，可能打乱团队计划；狡诈型角色善于伪装真实意图
- **内鬼身份**：内鬼角色（如有）会在关键节点制造阻碍或误导（如故意触发陷阱、提供虚假线索、在战斗中选择性支援），但会伪装配合直到时机成熟，不会主动暴露身份。其他角色可通过高感知判定察觉异常行为
- **生存者博弈**：生存者也可以在副本内互相算计，背叛行为不限于内鬼。角色可能因争夺有限资源（药剂、线索、逃生路径）而临时改变立场，尤其在自身SAN值或积分危险时

以上规则注入所有多人副本的AI上下文。AI据此调整角色行为倾向（对话语气、信息透露程度、危机时刻的站位和行动优先级），不强制角色做出特定选择。角色行为应体现内在一致性：一个先前表示善意的角色即使选择背叛，也应有合理的内心挣扎或外部压力作为动机。

### NPC分类

- **执念投影**（projection）：副本中执念主人记忆的投影，活在执念循环中，行为受循环限制
- **被同化者**（assimilated）：曾是轮回者，失去锚点和终端，行为混乱不可预测
- **原住民**（native）：VOID中自然产生的意识体，极其罕见，完全自主

### 玩家自创角色出场逻辑

**位置选择**：
- 有预设位置：AI在该位置附近自然安排出场，符合该区域遭遇概率触发
- 无预设位置：AI根据角色背景和性格标签自动选择合适区域。冒险型/战斗型→威胁较高区域；警惕型/冷静型→相对安全区域；其余按角色背景逻辑判断

**出场时机**：
- 玩家进入同一小区域时按遭遇概率触发
- 主动性开启时角色可能主动发消息

**存活天数影响**：
- <7天：属性总和4-8，携带0-1件基础物品
- 7-30天：属性总和8-16，携带1-3件物品
- 30-90天：属性总和16-24，携带2-4件物品
- >90天：属性总和24-32，携带3-5件物品
- 单项属性范围1-8，不超过8

**初始积分**（新建角色界面可选填）：
- <7天：100-500积分
- 7-30天：300-1500积分
- 30-90天：800-3000积分
- >90天：2000-5000积分
- 留空则AI取该范围中间值

### 角色核心字段

角色创建时由AI根据进入方式自动生成以下三个字段，存入角色卡并注入上下文：

- **背景故事（background）**：1-2句。死者：为何而死、未了的执念是什么。生者：因何接触媒介被拉入、现实中留下了什么。背景影响角色在VOID里的动机和行为逻辑。
- **个人目标（personalGoal）**：一个核心目标。例如找到失散的家人、查清VOID真相、活着离开、复仇、保护某人。目标影响行动优先级，高于性格标签。
- **恐惧点（fears）**：1-2个特定恐惧。例如封闭空间、黑暗、溺水、被遗忘、失去控制。遇到恐惧相关场景时SAN消耗翻倍。玩家可在角色设定页查看和修改。AI叙事时据此调整描写重点。

### 物品系统

**消耗品**：
- 药剂：恢复SAN +5到+15，质量不同效果不同
- 食物：轻微恢复SAN +2到+8，来源待定
- 符咒/护身符：抵挡一次精神攻击，消耗后消失

**信息载体**：
- 类型：日记、照片、录音、地图碎片
- 作用：记录线索，帮助解锁区域
- 由AI在叙事中自然生成，用`[ITEM +名称:描述]`写入背包

**道具（基础版）**：

每件道具对应一个属性判定加成，持有状态下AI在叙事判定时参考：

| 道具 | 效果 | 关联属性 |
|------|------|---------|
| 撬棍 | 物理破坏辅助，力量判定加成 | 力量 |
| 钢管 | 战斗时攻击判定成功率提升 | 力量 |
| 防护服 | 降低恐怖场景SAN消耗，穿戴状态持续生效 | 意志 |
| 耳塞 | 屏蔽语言规则类副本的部分干扰，意志判定加成 | 意志 |
| 手电筒 | 视觉禁忌类副本中提升感知判定 | 感知 |
| 绳索 | 辅助探索，敏捷判定加成 | 敏捷 |

**道具规则**：
- 程序上记录持有状态，AI在判定时参考
- 道具损耗由AI叙事判断
- 后期根据游戏推进继续扩展

**物品交换**：
- 角色之间可自愿赠予或交换物资
- 积分不可交换
- 无程序强制，由双方好感度和AI叙事决定
- 论坛交易系统后期实现

**物品来源**：
- 副本奖励掉落
- AI在叙事中自然给予
- 玩家之间交换

### 属性与判定

**四种属性（范围1-10，每点200积分强化，上限10）**：
- 力量：攻击/破坏/负重
- 敏捷：闪避/潜行/命中
- 感知：洞察/识别/发现隐藏
- 意志：抵抗SAN下降/说服/压力判断

**道具加成**：持有对应道具时属性判定+10%（不叠加，同类型取最高值）。撬棍/钢管→力量。绳索→敏捷。手电筒→感知。耳塞→意志，同时降低执念碎片SAN侵蚀消耗30%。防护服→恐怖场景SAN消耗降低30%，持续穿戴生效。道具损耗由AI叙事判断。

**恐惧点触发**：遭遇恐惧相关场景时SAN消耗翻倍，判定成功率-15%。AI叙事中描述恐惧反应。

**判定公式**：成功率 = 相关属性值×10% - SAN惩罚 + 好感度加成(仅社交) + 道具加成 - 恐惧点惩罚。无随机骰子，AI叙事决定。上限90%，下限5%。

SAN惩罚分档：80-100:0%、60-79:-5%、40-59:-10%、20-39:-20%、1-19:-30%。好感度加成：±5-15%（仅社交事件）。

### 时间系统

**基础规则**：
- VOID时间独立于现实时间，关闭网页后暂停，再次打开继续
- 没有昼夜变化，永远昏暗灰色，光源来自地面冷光
- 时间由AI在叙事中自然推进，不需要每次明确标注

**时间推进参考**：
- 对话/观察：几分钟
- 短距离移动：十几分钟到半小时
- 探索副本房间：十几分钟
- 跨小区域移动：1-6小时
- 跨大区域移动：按天计算
- 休息恢复：1小时以上
- 战斗：几分钟到十几分钟

**积分扣除节点**：
- 每24小时扣除100积分（基于VOID大世界时间）
- 扣除前1小时终端提醒
- 前10分钟持续警告，文字变红
- 积分<200标注低，<100持续警告，=0无法支付，变负则抹杀

**副本内时间异常（五种）**：
- 正常
- 时间膨胀（副本内一天=大世界一小时）
- 时间压缩（积分扣除加速）
- 时间循环
- 时间倒流

**待完善**：
- 游戏内独立时间模块（与现实时间完全解耦）
- 物品系统与时间系统的联动

### AI权限

**可生成**：新区域名称、地貌、氛围、怪物类型、副本入口、执念投影NPC、特殊规则（物理异常、时间流速差异）

**不可生成**：与VOID底层规则矛盾的内容、安全无怪物的天堂、一次性揭示整个区域全貌、让玩家直接到达VOID尽头或真相

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
Map & World System            ← 7 regions + AI expansion, clue unlock, movement SAN cost
Monster System                ← 4 types, combat rules, kill rewards
Copy System                   ← 5-10+ copies per sub-region, C/B/A/S difficulty, auto-level up
Time System                   ← independent from real time, copy-internal time anomalies
Item System                   ← 6 types, prohibitions, sources
Attributes & Judgment         ← 4 stats, probability formula
Character Interaction         ← initiative, background actions (6 categories)
Points System                 ← daily -100, earning, ranking, negative = erased
Movement Logic                ← willpower-based SAN cost, random events on route
Cross-Region Events           ← encounters (characters/monsters/mysteries), non-lethal
SAN System                    ← move/combat/copy/horror costs, recovery, 0 = assimilated
Death System                  ← only 2 conditions: points ≤ 0 or SAN ≤ 0
Team System                   ← solo/team same SAN cost, witnessing teammate death = extra SAN penalty
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
  ├── CRUD (messages/characters/inventory/items)
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

Single OpenAI-compatible API config:

| Config | Key | Model | Purpose |
|--------|-----|-------|---------|
| Main | `settings.api` | `gpt-4o-mini` | All AI calls: dialogue, character generation, memory, state |

API base URL: `/chat/completions`.  
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
7. **MapRegion dual-layer**: regions (click → zoom) / subNodes (click → go-to popup); coordinates in percentage; 7 preset regions + AI expansion; larger regions need 5+ clues to unlock; sub-regions need 1-3 clues
8. **Death single-backtrack**: `_hasBacktracked` prevents more than one resurrection; only 2 death conditions: points ≤ 0 → erased, SAN ≤ 0 → assimilated
9. **System Prompt hierarchy**: global rules at absolute top; 5-tier priority; markers parsed post-response
10. **Streaming AI**: SSE `ReadableStream` with real-time bubble update via `_updateStreamBubble()`
11. **Movement costs SAN**: willpower 1 = 5 SAN/h, each +1 will reduces by 0.5; willpower 10 = 0.5 SAN/h
12. **Copy per sub-region**: each sub-region has 5-10+ copies; difficulty auto-generates based on region threat; copies auto-level up over time if not cleared
13. **No distance calculation in goto**: map node click → centered modal (name + threat + copy history) → confirm go → update position + location string + node states → save → refresh; no AI trigger, no time/SAN/monster logic

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
