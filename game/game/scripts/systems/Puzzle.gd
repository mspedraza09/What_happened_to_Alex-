# Puzzle.gd — TAD 2
# Reto que el jugador debe resolver. Componente aleatorio via RandomLCG.
# Uso: var p = Puzzle.new("puzzle1", "clue1", "C", "Descripcion", hints_arraylist)

class_name Puzzle

var _puzzle_id:    String
var _clue_key:     String
var _answer:       String
var _description:  String
var _hints:        ArrayList
var _max_attempts: int
var _attempts:     int
var _solved:       bool

var _rng: RandomLCG

func _init(puzzle_id: String, clue_key: String, answer: String,
		   description: String, hints: ArrayList, max_attempts: int = 3) -> void:
	if puzzle_id == "" or answer == "":
		push_error("Puzzle: puzzle_id y answer no pueden estar vacios.")
		return
	if max_attempts < 1:
		push_error("Puzzle: max_attempts debe ser >= 1.")
		return
	_puzzle_id    = puzzle_id
	_clue_key     = clue_key
	_answer       = answer.strip_edges().to_lower()
	_description  = description
	_hints        = hints if hints != null else ArrayList.new()
	_max_attempts = max_attempts
	_attempts     = 0
	_solved       = false
	_rng          = RandomLCG.new()

func get_puzzle_id()   -> String: return _puzzle_id
func get_clue_key()    -> String: return _clue_key
func get_description() -> String: return _description
func get_attempts()    -> int:    return _attempts
func is_solved()       -> bool:   return _solved
func needs_extra_help() -> bool:
	return _attempts >= _max_attempts and not _solved

func check_answer(answer: String) -> bool:
	if _solved:
		return true
	if answer.strip_edges() == "":
		return false
	_attempts += 1
	if answer.strip_edges().to_lower() == _answer:
		_solved = true
		return true
	return false

func get_random_hint() -> String:
	# COMPONENTE ALEATORIO — LCG propio
	if _hints.is_empty():
		return "Sigue investigando."
	var idx := _rng.next_range(0, _hints.size())
	return _hints.get_at(idx)

func reset() -> void:
	_attempts = 0
	_solved   = false

func to_map() -> HashMap:
	var m := HashMap.new()
	m.put("puzzle_id",   _puzzle_id)
	m.put("clue_key",    _clue_key)
	m.put("description", _description)
	m.put("attempts",    _attempts)
	m.put("solved",      _solved)
	return m

func to_string() -> String:
	var s := "OK" if _solved else "(%d intentos)" % _attempts
	return "Puzzle(%s, %s)" % [_puzzle_id, s]

func restore(saved_attempts: int, saved_solved: bool) -> void:
    """
    Restaura el estado del puzzle desde un guardado.
    Solo llamado por PersistenceManager — no usar en otro contexto.
    """
    _attempts = saved_attempts
    _solved   = saved_solved

# ── Métodos de restauración (usados por PersistenceManager) ──

func restore_solved(attempts: int) -> void:
	# Restaura el puzzle como resuelto con los intentos guardados
	_attempts = attempts
	_solved   = true

func restore_attempts(attempts: int) -> void:
	# Restaura los intentos sin marcar como resuelto
	_attempts = attempts
	_solved   = false
