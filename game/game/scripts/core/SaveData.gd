# SaveData.gd
# TAD 7 — Datos de guardado del juego.
#
# Encapsula exactamente lo que se necesita guardar entre sesiones:
#   - Etapa actual del jugador
#   - Pistas obtenidas (key + value)
#   - Puzzles resueltos (id + intentos)
#
# No guarda objetos completos — solo los datos primitivos necesarios
# para reconstruir el GameState al cargar.
#
# Formato del archivo .sav (texto plano, sin JSON nativo):
#
#   SAVE_VERSION:1
#   STAGE:midway
#   CLUE:clue1:C
#   CLUE:clue2:iber
#   PUZZLE:puzzle1:3:true
#   PUZZLE:puzzle2:1:true
#   PUZZLE:puzzle3:0:false
#   END
#
# Separador de campos: ":" (dos puntos)
# Cada línea es un registro independiente.

class_name SaveData

const SAVE_VERSION  := "1"
const SEP           := ":"       # separador de campos
const LINE_STAGE    := "STAGE"
const LINE_CLUE     := "CLUE"
const LINE_PUZZLE   := "PUZZLE"
const LINE_VERSION  := "SAVE_VERSION"
const LINE_END      := "END"

# ── Campos ──────────────────────────────────────────────────
var version:  String
var stage:    String

# ArrayList de HashMap — cada HashMap tiene: key, value
var clues:    ArrayList

# ArrayList de HashMap — cada HashMap tiene: puzzle_id, attempts, solved
var puzzles:  ArrayList

# ── Constructor ─────────────────────────────────────────────
func _init() -> void:
	version = SAVE_VERSION
	stage   = "locked"
	clues   = ArrayList.new()
	puzzles = ArrayList.new()

# ── Agregar datos ────────────────────────────────────────────
func add_clue(clue_key: String, clue_value: String) -> void:
	var m := HashMap.new()
	m.put("key",   clue_key)
	m.put("value", clue_value)
	clues.append(m)

func add_puzzle(puzzle_id: String, attempts: int, solved: bool) -> void:
	var m := HashMap.new()
	m.put("puzzle_id", puzzle_id)
	m.put("attempts",  attempts)
	m.put("solved",    solved)
	puzzles.append(m)

# ── Serializar a texto ───────────────────────────────────────
# Convierte el SaveData a una cadena de texto lista para escribir al disco.
func serialize() -> String:
	var lines := ArrayList.new()

	lines.append(LINE_VERSION + SEP + version)
	lines.append(LINE_STAGE   + SEP + stage)

	# Una línea por cada pista obtenida
	for i in range(clues.size()):
		var c: HashMap = clues.get_at(i)
		lines.append(
			LINE_CLUE + SEP +
			str(c.get_val("key")) + SEP +
			str(c.get_val("value"))
		)

	# Una línea por cada puzzle (guardamos todos, resueltos o no)
	for i in range(puzzles.size()):
		var p: HashMap = puzzles.get_at(i)
		lines.append(
			LINE_PUZZLE + SEP +
			str(p.get_val("puzzle_id")) + SEP +
			str(p.get_val("attempts"))  + SEP +
			str(p.get_val("solved"))
		)

	lines.append(LINE_END)

	# Unir con saltos de línea
	var result := ""
	for i in range(lines.size()):
		result += lines.get_at(i)
		if i < lines.size() - 1:
			result += "\n"
	return result

# ── Deserializar desde texto ─────────────────────────────────
# Reconstruye un SaveData desde una cadena de texto leída del disco.
# Retorna null si el formato es inválido.
static func deserialize(text: String) -> SaveData:
	if text == null or text.strip_edges() == "":
		return null

	var sd   := SaveData.new()
	var valid := false

	# Dividir por saltos de línea manualmente (sin split nativo)
	var lines := _split_lines(text)

	for i in range(lines.size()):
		var line: String = lines.get_at(i).strip_edges()
		if line == "" or line.begins_with("#"):
			continue

		# Dividir la línea por el separador ":"
		var parts := _split_line(line, SEP)
		if parts.size() == 0:
			continue

		var tag: String = parts.get_at(0)

		if tag == LINE_END:
			valid = true
			break

		elif tag == LINE_VERSION:
			if parts.size() >= 2:
				sd.version = parts.get_at(1)

		elif tag == LINE_STAGE:
			if parts.size() >= 2:
				sd.stage = parts.get_at(1)

		elif tag == LINE_CLUE:
			# CLUE:clue_key:clue_value
			if parts.size() >= 3:
				sd.add_clue(parts.get_at(1), parts.get_at(2))

		elif tag == LINE_PUZZLE:
			# PUZZLE:puzzle_id:attempts:solved
			if parts.size() >= 4:
				var pid      := parts.get_at(1)
				var attempts := int(parts.get_at(2))
				var solved   := parts.get_at(3).to_lower() == "true"
				sd.add_puzzle(pid, attempts, solved)

	if not valid:
		push_error("SaveData.deserialize: archivo corrupto o incompleto.")
		return null

	return sd

# ── Utilidades internas de parsing ───────────────────────────
# Divide un texto por saltos de línea sin usar split() nativo.
static func _split_lines(text: String) -> ArrayList:
	var result  := ArrayList.new()
	var current := ""
	for i in range(text.length()):
		var ch := text[i]
		if ch == "\n":
			result.append(current)
			current = ""
		elif ch != "\r":
			current += ch
	if current != "":
		result.append(current)
	return result

# Divide una línea por un separador sin usar split() nativo.
static func _split_line(line: String, sep: String) -> ArrayList:
	var result  := ArrayList.new()
	var current := ""
	for i in range(line.length()):
		var ch := line[i]
		if ch == sep:
			result.append(current)
			current = ""
		else:
			current += ch
	if current != "":
		result.append(current)
	return result

func to_string() -> String:
	return "SaveData(version=%s, stage=%s, clues=%d, puzzles=%d)" % [
		version, stage, clues.size(), puzzles.size()
	]
