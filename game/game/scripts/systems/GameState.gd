# GameState.gd — TAD 5
# Estado completo del juego. Construye clues y puzzles internamente.

class_name GameState

var _tracker:  ProgressTracker
var _puzzles:  HashMap          # HashMap<String, Puzzle>
var _cur_app:  String
var _err_msg:  String
var _fb_msg:   String

var _rng: RandomLCG

# Mensajes aleatorios
var _motivational: ArrayList
var _wrong_pwd:    ArrayList

func _init() -> void:
	_rng     = RandomLCG.new()
	_cur_app = ""
	_err_msg = ""
	_fb_msg  = ""

	# ── Pistas ──────────────────────────────────────────
	var clues := ArrayList.new()
	clues.append(Clue.new("clue1", "Archivo de trabajo",
		"Letras resaltadas en el archivo de criptografia."))
	clues.append(Clue.new("clue2", "Mensaje cifrado",
		"Usa el cifrado Cesar del archivo."))
	clues.append(Clue.new("clue3", "Apodo de Alex",
		"Apodo censurado en chats y red social."))

	_tracker = ProgressTracker.new(clues)

	# ── Hints por puzzle ────────────────────────────────
	var h1 := ArrayList.new()
	h1.append("Abre Archivos y busca el documento de criptografia.")
	h1.append("Las letras resaltadas estan en el texto del archivo.")
	h1.append("Solo una letra esta destacada.")

	var h2 := ArrayList.new()
	h2.append("Recuerda el cifrado Cesar del archivo.")
	h2.append("Desplaza cada letra el numero indicado.")
	h2.append("El mensaje esta en el perfil diferente del buscador.")

	var h3 := ArrayList.new()
	h3.append("El apodo aparece en chats y red social.")
	h3.append("Letras censuradas con asteriscos.")
	h3.append("Identifica el patron y reconstruye la palabra.")

	# ── Puzzles ─────────────────────────────────────────
	_puzzles = HashMap.new()
	_puzzles.put("puzzle1", Puzzle.new(
		"puzzle1", "clue1", "C",
		"Letras resaltadas en el archivo de trabajo.", h1))
	_puzzles.put("puzzle2", Puzzle.new(
		"puzzle2", "clue2", "iber",
		"Descifra el mensaje del perfil inusual.", h2))
	_puzzles.put("puzzle3", Puzzle.new(
		"puzzle3", "clue3", "acoso",
		"Reconstruye el apodo de Alex.", h3))

	# ── Mensajes aleatorios ─────────────────────────────
	_motivational = ArrayList.new()
	_motivational.append("Buen ojo! Cada detalle cuenta.")
	_motivational.append("Vas por buen camino! Sigue investigando.")
	_motivational.append("Excelente! Una pieza mas del rompecabezas.")
	_motivational.append("Increible! Alex cuenta contigo.")
	_motivational.append("Eso es! La verdad se esta revelando.")

	_wrong_pwd = ArrayList.new()
	_wrong_pwd.append("Contrasena incorrecta. Revisa las pistas de la carta.")
	_wrong_pwd.append("Eso no es correcto. Lee la carta con cuidado.")
	_wrong_pwd.append("Intenta de nuevo. La respuesta esta en la carta.")

func get_tracker() -> ProgressTracker: return _tracker
func get_stage()   -> String:          return _tracker.get_stage()
func get_current_app() -> String:      return _cur_app
func get_error_message() -> String:    return _err_msg
func get_last_feedback() -> String:    return _fb_msg

func set_current_app(app: String) -> void: _cur_app = app
func set_error(msg: String)   -> void: _err_msg = msg; _fb_msg  = ""
func set_feedback(msg: String) -> void: _fb_msg  = msg; _err_msg = ""
func clear_messages()         -> void: _err_msg = ""; _fb_msg = ""

func get_puzzle_by_clue(clue_key: String) -> Puzzle:
	var vals := _puzzles.values()
	for i in range(vals.size()):
		var p: Puzzle = vals.get_at(i)
		if p.get_clue_key() == clue_key:
			return p
	return null

func rand_motivational() -> String:
	if _motivational.is_empty():
		return ""
	return _motivational.get_at(_rng.next_range(0, _motivational.size()))

func rand_wrong_pwd() -> String:
	if _wrong_pwd.is_empty():
		return "Contrasena incorrecta."
	return _wrong_pwd.get_at(_rng.next_range(0, _wrong_pwd.size()))

func full_summary() -> HashMap:
	var m := HashMap.new()
	m.put("stage",       get_stage())
	m.put("current_app", _cur_app)
	m.put("error",       _err_msg)
	m.put("feedback",    _fb_msg)
	m.put("progress",    _tracker.summary())
	return m
