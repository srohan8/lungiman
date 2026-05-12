extends Node

## SaveManager — persists GameManager stats + QuestManager state to user://save.json.
## Autoload. Call save_game() on act completion / quit; load_game() on MainMenu _ready().

const SAVE_PATH := "user://save.json"

func save_game() -> void:
	var qm := get_node_or_null("/root/QuestManager")
	var data := {
		"version":          3,
		"score":            GameManager.score,
		"high_score":       GameManager.high_score,
		"acts_unlocked":    GameManager.acts_unlocked,
		"has_resurrection": GameManager.has_resurrection,
		"quests":           _serialise_quests(qm),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text   := file.get_as_text()
	file.close()
	var result := JSON.parse_string(text)
	if result == null or not result is Dictionary:
		return
	var data: Dictionary = result
	GameManager.score            = data.get("score",            0)
	GameManager.high_score       = data.get("high_score",       0)
	GameManager.acts_unlocked    = data.get("acts_unlocked",    0)
	GameManager.has_resurrection = data.get("has_resurrection", false)
	var qm := get_node_or_null("/root/QuestManager")
	if qm != null:
		_deserialise_quests(qm, data.get("quests", {}))

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# ── Internal ──────────────────────────────────────────────────────────────────

func _serialise_quests(qm: Node) -> Dictionary:
	var out := {}
	if qm == null: return out
	for quest_id: String in qm.QUEST_DATA:
		out[quest_id] = {
			"state":    qm.get_state(quest_id),
			"progress": qm.get_progress(quest_id),
		}
	return out

func _deserialise_quests(qm: Node, quests: Dictionary) -> void:
	for quest_id: String in quests:
		if not qm.QUEST_DATA.has(quest_id): continue
		var entry: Dictionary = quests[quest_id]
		var state:    int = entry.get("state",    0)
		var progress: int = entry.get("progress", 0)
		match state:
			1:   # ACTIVE
				qm.activate_quest(quest_id)
				if progress > 0:
					qm.advance_quest(quest_id, progress)
			2:   # DONE
				qm.complete_quest(quest_id)
