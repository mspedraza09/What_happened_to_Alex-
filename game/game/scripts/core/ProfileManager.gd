# ProfileManager.gd
# TAD 10 — Gestor de perfiles de jugadores.
#
# Responsabilidad unica: administrar los perfiles registrados.
# Lee y escribe el indice de jugadores (players.idx).
# Cada jugador tiene su propio archivo .sav separado.
#
# Estructura de archivos en disco:
#   user://players.idx          <- indice de todos los jugadores
#   user://save_alejandro.sav   <- guardado de alejandro
#   user://save_maria.sav       <- guardado de maria
#   user://save_anny.sav        <- guardado de anny
#
# Formato de players.idx:
#   INDEX_VERSION:1
#   PLAYER:alejandro:Alejandro Cotes:2026-05-01:2026-05-10
#   PLAYER:maria:Maria Sierra:2026-05-01:2026-05-08
#   PLAYER:anny:Anny Delgado:2026-05-02:2026-05-09
#   END
#
# Uso:
#   ProfileManager.create_profile("alejandro", "Alejandro Cotes")
#   var profiles = ProfileManager.get_all_profiles()
#   ProfileManager.delete_profile("alejandro")
#   var exists = ProfileManager.profile_exists("maria")

class_name ProfileManager

const INDEX_PATH    := "user://players.idx"
const INDEX_VERSION := "1"
const SEP           := ":"
const TAG_VERSION   := "INDEX_VERSION"
const TAG_PLAYER    := "PLAYER"
const TAG_END       := "END"
const MAX_PLAYERS   := 10

# ============================================================
# CREAR PERFIL
# Registra un nuevo jugador en el indice.
# Retorna true si se creo correctamente.
# Retorna false si el username ya existe o hay error.
# ============================================================
static func create_profile(username: String, display_name: String) -> bool:
	var uname := username.strip_edges().to_lower()
	var dname := display_name.strip_edges()

	if uname == "":
		push_error("ProfileManager.create_profile: username vacio.")
		return false

	if profile_exists(uname):
		push_error("ProfileManager.create_profile: '%s' ya existe." % uname)
		return false

	var profiles := get_all_profiles()
	if profiles.size() >= MAX_PLAYERS:
		push_error("ProfileManager.create_profile: limite de jugadores alcanzado.")
		return false

	var date := _today()
	var p    := PlayerProfile.new(uname, dname, date)
	profiles.append(p)

	return _write_index(profiles)

# ============================================================
# OBTENER TODOS LOS PERFILES
# Retorna un ArrayList<PlayerProfile> con todos los jugadores.
# Retorna ArrayList vacio si no hay ninguno.
# ============================================================
static func get_all_profiles() -> ArrayList:
	if not FileAccess.file_exists(INDEX_PATH):
		return ArrayList.new()
	return _read_index()

# ============================================================
# OBTENER UN PERFIL POR USERNAME
# Retorna el PlayerProfile o null si no existe.
# ============================================================
static func get_profile(username: String) -> PlayerProfile:
	var uname    := username.strip_edges().to_lower()
	var profiles := get_all_profiles()
	for i in range(profiles.size()):
		var p: PlayerProfile = profiles.get_at(i)
		if p.username == uname:
			return p
	return null

# ============================================================
# VERIFICAR SI UN PERFIL EXISTE
# ============================================================
static func profile_exists(username: String) -> bool:
	return get_profile(username) != null

# ============================================================
# ACTUALIZAR ULTIMA VEZ QUE JUGO
# Llamar cada vez que el jugador guarda su partida.
# ============================================================
static func update_last_played(username: String) -> void:
	var uname    := username.strip_edges().to_lower()
	var profiles := get_all_profiles()
	for i in range(profiles.size()):
		var p: PlayerProfile = profiles.get_at(i)
		if p.username == uname:
			p.last_played = _today()
	_write_index(profiles)

# ============================================================
# ELIMINAR PERFIL
# Borra el perfil del indice Y su archivo de guardado.
# ============================================================
static func delete_profile(username: String) -> bool:
	var uname    := username.strip_edges().to_lower()
	var profiles := get_all_profiles()
	var updated  := ArrayList.new()
	var found    := false

	for i in range(profiles.size()):
		var p: PlayerProfile = profiles.get_at(i)
		if p.username == uname:
			found = true
			# Borrar su archivo .sav
			var save_path := p.get_save_path()
			if FileAccess.file_exists(save_path):
				DirAccess.remove_absolute(
					ProjectSettings.globalize_path(save_path)
				)
		else:
			updated.append(p)

	if not found:
		return false

	return _write_index(updated)

# ============================================================
# GUARDAR PARTIDA DE UN JUGADOR ESPECIFICO
# ============================================================
static func save_player_game(username: String, state: GameState) -> bool:
	var uname := username.strip_edges().to_lower()
	var p     := get_profile(uname)
	if p == null:
		push_error("ProfileManager.save_player_game: perfil '%s' no existe." % uname)
		return false

	# Construir SaveData y escribir al archivo del jugador
	var sd   := _build_save_data(state)
	if sd == null:
		return false

	var text := sd.serialize()
	var file := FileAccess.open(p.get_save_path(), FileAccess.WRITE)
	if file == null:
		push_error("ProfileManager.save_player_game: no se pudo escribir.")
		return false

	file.store_string(text)
	file.close()

	# Actualizar fecha de ultimo juego
	update_last_played(uname)
	return true

# ============================================================
# CARGAR PARTIDA DE UN JUGADOR ESPECIFICO
# Retorna SaveData o null si no tiene guardado.
# ============================================================
static func load_player_game(username: String) -> SaveData:
	var uname := username.strip_edges().to_lower()
	var p     := get_profile(uname)
	if p == null:
		return null

	var path := p.get_save_path()
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var text := file.get_as_text()
	file.close()

	if text.strip_edges() == "":
		return null

	return SaveData.deserialize(text)

# ============================================================
# VERIFICAR SI UN JUGADOR TIENE PARTIDA GUARDADA
# ============================================================
static func player_has_save(username: String) -> bool:
	var p := get_profile(username.strip_edges().to_lower())
	if p == null:
		return false
	return FileAccess.file_exists(p.get_save_path())

# ============================================================
# BORRAR SOLO LA PARTIDA DE UN JUGADOR (no el perfil)
# ============================================================
static func delete_player_save(username: String) -> bool:
	var p := get_profile(username.strip_edges().to_lower())
	if p == null:
		return false
	var path := p.get_save_path()
	if not FileAccess.file_exists(path):
		return true
	var err := DirAccess.remove_absolute(
		ProjectSettings.globalize_path(path)
	)
	return err == OK

# ============================================================
# INTERNO — leer el indice de perfiles
# ============================================================
static func _read_index() -> ArrayList:
	var result := ArrayList.new()

	var file := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null:
		return result

	var text  := file.get_as_text()
	file.close()

	var lines := _split_lines(text)

	for i in range(lines.size()):
		var line: String = lines.get_at(i).strip_edges()
		if line == "" or line == TAG_END:
			continue

		var parts := _split_by(line, SEP)
		if parts.size() == 0:
			continue

		var tag: String = parts.get_at(0)

		if tag == TAG_PLAYER and parts.size() >= 5:
			# PLAYER:username:display_name:created_at:last_played
			var uname   := parts.get_at(1)
			var dname   := parts.get_at(2)
			var created := parts.get_at(3)
			var last    := parts.get_at(4)
			var p       := PlayerProfile.new(uname, dname, created)
			p.last_played = last
			result.append(p)

	return result

# ============================================================
# INTERNO — escribir el indice de perfiles
# ============================================================
static func _write_index(profiles: ArrayList) -> bool:
	var lines := ArrayList.new()
	lines.append(TAG_VERSION + SEP + INDEX_VERSION)

	for i in range(profiles.size()):
		var p: PlayerProfile = profiles.get_at(i)
		lines.append(
			TAG_PLAYER + SEP +
			p.username     + SEP +
			p.display_name + SEP +
			p.created_at   + SEP +
			p.last_played
		)

	lines.append(TAG_END)

	var text := ""
	for i in range(lines.size()):
		text += lines.get_at(i)
		if i < lines.size() - 1:
			text += "\n"

	var file := FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ProfileManager._write_index: no se pudo escribir.")
		return false

	file.store_string(text)
	file.close()
	return true

# ============================================================
# INTERNO — construir SaveData desde GameState
# ============================================================
static func _build_save_data(state: GameState) -> SaveData:
	var sd      := SaveData.new()
	var tracker := state.get_tracker()
	sd.stage     = tracker.get_stage()

	var all_clues := tracker.all_clues()
	for i in range(all_clues.size()):
		var c: Clue = all_clues.get_at(i)
		if c.is_collected():
			sd.add_clue(c.get_key(), c.get_value())

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

# ============================================================
# INTERNO — parseo manual sin split() nativo
# ============================================================
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

static func _split_by(line: String, sep: String) -> ArrayList:
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

static func _today() -> String:
	var t := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t["year"], t["month"], t["day"]]
