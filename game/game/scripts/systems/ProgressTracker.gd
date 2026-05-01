# ProgressTracker.gd — TAD 3
# Rastrea etapa y pistas del jugador. SOLID SRP.
# Uso: var tracker = ProgressTracker.new(clues_arraylist)

class_name ProgressTracker

const STAGE_LOCKED   := "locked"
const STAGE_INTRO    := "intro"
const STAGE_MIDWAY   := "midway"
const STAGE_ADVANCED := "advanced"
const STAGE_FINAL    := "final_lock"
const STAGE_COMPLETE := "complete"

var _stage:   String
var _clues:   HashMap   # HashMap<String, Clue>
var _history: ArrayList # ArrayList<String>

var _stage_order: ArrayList

func _init(clues: ArrayList) -> void:
	if clues == null or clues.is_empty():
		push_error("ProgressTracker: necesita al menos una pista.")
		return
	_stage   = STAGE_LOCKED
	_clues   = HashMap.new()
	_history = ArrayList.new()

	for i in range(clues.size()):
		var c: Clue = clues.get_at(i)
		_clues.put(c.get_key(), c)

	_stage_order = ArrayList.new()
	_stage_order.append(STAGE_LOCKED)
	_stage_order.append(STAGE_INTRO)
	_stage_order.append(STAGE_MIDWAY)
	_stage_order.append(STAGE_ADVANCED)
	_stage_order.append(STAGE_FINAL)
	_stage_order.append(STAGE_COMPLETE)

func get_stage() -> String:
	return _stage

func advance_stage(new_stage: String) -> void:
	var new_idx := _stage_order.index_of(new_stage)
	if new_idx == -1:
		push_error("ProgressTracker: etapa desconocida: " + new_stage)
		return
	if new_idx <= _stage_order.index_of(_stage):
		return
	_stage = new_stage
	_history.append("Etapa -> " + new_stage)

func collect_clue(clue_key: String, value: String) -> void:
	if not _clues.contains_key(clue_key):
		push_error("ProgressTracker: pista '" + clue_key + "' no existe.")
		return
	var c: Clue = _clues.get_val(clue_key)
	c.collect(value)
	_history.append("Pista: " + clue_key + "='" + value + "'")

func get_clue(clue_key: String) -> Clue:
	return _clues.get_val(clue_key, null)

func all_clues() -> ArrayList:
	return _clues.values()

func collected_count() -> int:
	var n := 0
	var vals := _clues.values()
	for i in range(vals.size()):
		var c: Clue = vals.get_at(i)
		if c.is_collected():
			n += 1
	return n

func all_collected() -> bool:
	var vals := _clues.values()
	for i in range(vals.size()):
		var c: Clue = vals.get_at(i)
		if not c.is_collected():
			return false
	return true

func has_clue(clue_key: String) -> bool:
	var c: Clue = _clues.get_val(clue_key, null)
	return c != null and c.is_collected()

func get_history() -> ArrayList:
	return _history

func summary() -> HashMap:
	var m := HashMap.new()
	m.put("stage",     _stage)
	m.put("collected", collected_count())
	m.put("total",     _clues.size())
	return m

func to_string() -> String:
	return "ProgressTracker(stage=%s, clues=%d/%d)" % [
		_stage, collected_count(), _clues.size()
	]
