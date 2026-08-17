extends RefCounted
class_name GameSession

const MODE_SAVE_PATH = "user://modela_con_juli_mode.json"
const SCORE_SAVE_PATH = "user://modela_con_juli_scores.json"
const DEFAULT_MODE = "classic"
const VALID_MODES = ["classic", "duel", "daily"]

static func save_mode(mode: String) -> void:
	var resolved = mode if VALID_MODES.has(mode) else DEFAULT_MODE
	var file = FileAccess.open(MODE_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"mode": resolved}))

static func load_mode() -> String:
	if not FileAccess.file_exists(MODE_SAVE_PATH):
		return DEFAULT_MODE
	var file = FileAccess.open(MODE_SAVE_PATH, FileAccess.READ)
	if not file:
		return DEFAULT_MODE
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var mode = str(parsed.get("mode", DEFAULT_MODE))
		if VALID_MODES.has(mode):
			return mode
	return DEFAULT_MODE

static func record_score(score: int, mode: String, variant: String) -> void:
	var data = load_scores()
	var best = int(data.get("best", 0))
	data["best"] = max(best, score)
	data["last"] = score
	data["runs"] = int(data.get("runs", 0)) + 1
	data["mode"] = mode
	data["variant"] = variant

	var history = data.get("history", [])
	if not (history is Array):
		history = []
	history.push_front({"score": score, "mode": mode, "variant": variant})
	while history.size() > 8:
		history.pop_back()
	data["history"] = history

	var file = FileAccess.open(SCORE_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

static func load_scores() -> Dictionary:
	var fallback = {"best": 0, "last": 0, "runs": 0, "history": []}
	if not FileAccess.file_exists(SCORE_SAVE_PATH):
		return fallback
	var file = FileAccess.open(SCORE_SAVE_PATH, FileAccess.READ)
	if not file:
		return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return fallback
