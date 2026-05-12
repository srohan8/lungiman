extends Node

## QuestManager — autoload that tracks all side quest states.
## Usage: QuestManager.activate_quest("odiyan_tracks")
##        QuestManager.advance_quest("odiyan_tracks")
##        QuestManager.get_state("odiyan_tracks") → QuestState

enum QuestState { LOCKED, ACTIVE, DONE }

const QUEST_DATA := {
	"odiyan_tracks": {
		"title":       "Odiyan's Tracks",
		"desc":        "Find 4 hoof-prints in the foggy hills before facing the shapeshifter.",
		"act":         3,
		"total_steps": 4,
		"reward":      "Odiyan's vulnerable window extended (0.6s → 0.9s)",
	},
	"swing_off_race": {
		"title":       "Swing-off Race",
		"desc":        "Race Aniyandi Ravi crown-to-crown across 5 trees before he does.",
		"act":         1,
		"total_steps": 1,
		"reward":      "Unlocks Appam Glide — slow your fall mid-air",
	},
	"chaya_kada_showdown": {
		"title":       "Chaya Kada Showdown",
		"desc":        "Win the button-mash brawl at Soniya Chechi's tea stall.",
		"act":         1,
		"total_steps": 1,
		"reward":      "Ammo regens 2× faster near tea shops",
	},
	"bell_of_bhadrakali": {
		"title":       "Bell of Bhadrakali",
		"desc":        "Retrieve the temple bell from the ghostly houseboat on the backwater.",
		"act":         4,
		"total_steps": 1,
		"reward":      "Totem Revival — a second resurrection token",
	},
}

var _states:   Dictionary = {}   # quest_id → QuestState
var _progress: Dictionary = {}   # quest_id → int (steps completed)

signal quest_updated(quest_id: String, new_state: int)

func _ready() -> void:
	for id: String in QUEST_DATA:
		_states[id]   = QuestState.LOCKED
		_progress[id] = 0

# ── Public API ────────────────────────────────────────────────────────────────

func activate_quest(quest_id: String) -> void:
	if not QUEST_DATA.has(quest_id): return
	if _states[quest_id] == QuestState.DONE: return
	_states[quest_id] = QuestState.ACTIVE
	quest_updated.emit(quest_id, QuestState.ACTIVE)

func advance_quest(quest_id: String, steps: int = 1) -> void:
	if not QUEST_DATA.has(quest_id): return
	if _states[quest_id] != QuestState.ACTIVE: return
	_progress[quest_id] = mini(_progress[quest_id] + steps,
			QUEST_DATA[quest_id]["total_steps"])
	if _progress[quest_id] >= QUEST_DATA[quest_id]["total_steps"]:
		_complete(quest_id)
	else:
		quest_updated.emit(quest_id, QuestState.ACTIVE)

func complete_quest(quest_id: String) -> void:
	_complete(quest_id)

func get_state(quest_id: String) -> int:
	return _states.get(quest_id, QuestState.LOCKED)

func get_progress(quest_id: String) -> int:
	return _progress.get(quest_id, 0)

func get_total(quest_id: String) -> int:
	return QUEST_DATA.get(quest_id, {}).get("total_steps", 1)

func get_title(quest_id: String) -> String:
	return QUEST_DATA.get(quest_id, {}).get("title", quest_id)

func get_desc(quest_id: String) -> String:
	return QUEST_DATA.get(quest_id, {}).get("desc", "")

func get_reward(quest_id: String) -> String:
	return QUEST_DATA.get(quest_id, {}).get("reward", "")

func reset() -> void:
	for id: String in QUEST_DATA:
		_states[id]   = QuestState.LOCKED
		_progress[id] = 0

# ── Internal ──────────────────────────────────────────────────────────────────

func _complete(quest_id: String) -> void:
	if not QUEST_DATA.has(quest_id): return
	_states[quest_id]   = QuestState.DONE
	_progress[quest_id] = QUEST_DATA[quest_id]["total_steps"]
	quest_updated.emit(quest_id, QuestState.DONE)
