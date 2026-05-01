# PersistenceManager.gd
# TAD 8 - Sistema de persistencia del juego.
#
# Responsabilidad unica (SOLID SRP):
#   Solo maneja lectura y escritura del archivo de guardado.
#   No sabe nada de la logica del juego — solo traduce entre
#   GameState y el archivo en disco.
#
# Uso desde GameController:
#   var ok = PersistenceManager.save_game(state)
#   var sd = PersistenceManager.load_game()
#   if sd != null:
#       PersistenceManager.apply_to_state(sd, state)
#
# Archivo: user://alex_save.sav
# (user:// apunta a la carpeta de datos del usuario del SO)

class_name PersistenceManager

const SAVE_PATH := "user://alex_save.sav"

# ============================================================
# GUARDAR — toma el GameState y lo escribe al disco
# Retorna true si fue exitoso
# ============================================================
static func save_game(state: GameState) -> bool:
	var sd := _build_save_data(state)
	if sd == null:
		push_error("PersistenceManager.save_game: no se pudo construir SaveData.")
		return false

	var text := sd.serialize()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PersistenceManager.save_game: no se pudo abrir el archivo.")
		return false

	file.store_string(text)
	file.close()
	return true

# ============================================================
# CARGAR — lee el disco y retorna un SaveData
# Retorna null si no existe guardado o esta corrupto
# ============================================================
static func load_game() -> SaveData:
	if not FileAccess.file_exists(SAVE_PATH):
		return null

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("PersistenceManager.load_game: no se pudo abrir el archivo.")
		return null

	var text := file.get_as_text()
	file.close()

	if text.strip_edges() == "":
		return null

	return SaveData.deserialize(text)

# ============================================================
# APLICAR AL ESTADO — reconstruye el GameState desde SaveData
# Llamar justo despues de load_game() si retorno datos validos
# ============================================================
static func apply_to_state(sd: SaveData, state: GameState) -> void:
	if sd == null or state == null:
		push_error("PersistenceManager.apply_to_state: parametros nulos.")
		return

	var tracker := state.get_tracker()

	# 1. Restaurar etapa
	tracker.advance_stage(sd.stage)

	# 2. Restaurar pistas obtenidas
	for i in range(sd.clues.size()):
		var c: HashMap    = sd.clues.get_at(i)
		var key: String   = c.get_val("key",   "")
		var value: String = c.get_val("value", "")
		if key != "" and value != "":
			if not tracker.has_clue(key):
				tracker.collect_clue(key, value)

	# 3. Restaurar estado de puzzles
	for i in range(sd.puzzles.size()):
		var p: HashMap    = sd.puzzles.get_at(i)
		var pid: String   = p.get_val("puzzle_id", "")
		var attempts: int = p.get_val("attempts",  0)
		var solved: bool  = p.get_val("solved",    false)
		if pid == "":
			continue
		var puzzle: Puzzle = state.get_puzzle(pid)
		if puzzle == null:
			continue
		if solved:
			puzzle.restore_solved(attempts)
		else:
			puzzle.restore_attempts(attempts)

# ============================================================
# ELIMINAR GUARDADO — para nueva partida
# ============================================================
static func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var err := DirAccess.remove_absolute(
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if err != OK:
		push_error("PersistenceManager.delete_save: error al eliminar.")
		return false
	return true

# ============================================================
# VERIFICAR SI EXISTE GUARDADO
# ============================================================
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# ============================================================
# INTERNO — construir SaveData desde GameState
# ============================================================
static func _build_save_data(state: GameState) -> SaveData:
	var sd      := SaveData.new()
	var tracker := state.get_tracker()

	sd.stage = tracker.get_stage()

	# Pistas obtenidas
	var all_clues := tracker.all_clues()
	for i in range(all_clues.size()):
		var c: Clue = all_clues.get_at(i)
		if c.is_collected():
			sd.add_clue(c.get_key(), c.get_value())

	# Estado de todos los puzzles
	var puzzle_ids := ArrayList.new()
	puzzle_ids.append("puzzle1")
	puzzle_ids.append("puzzle2")
	puzzle_ids.append("puzzle3")

	for i in range(puzzle_ids.size()):
		var pid: String = puzzle_ids.get_at(i)
		var p: Puzzle   = state.get_puzzle(pid)
		if p != null:
			sd.add_puzzle(pid, p.get_attempts(), p.is_solved())

	return sd
