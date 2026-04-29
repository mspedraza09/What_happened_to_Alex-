# GameController.gd — TAD 6  (Facade + SOLID DIP)
# Punto de entrada unico para la UI (ANNY) y las apps (Maria).
# Adjuntalo a un nodo AutoLoad en Godot para acceso global:
#   Project > Project Settings > AutoLoad > GameController.gd como "GC"
#
# Desde la UI:
#   GC.subscribe("stage_changed", _on_stage_changed)
#   GC.unlock_phone("alex")
#
# Desde una app:
#   GC.submit_puzzle_answer("clue1", respuesta)
#   GC.is_app_unlocked("red_social")

class_name GameController

# ── Constantes de etapa ─────────────────────────────────────
const STAGE_LOCKED   := "locked"
const STAGE_INTRO    := "intro"
const STAGE_MIDWAY   := "midway"
const STAGE_ADVANCED := "advanced"
const STAGE_FINAL    := "final_lock"
const STAGE_COMPLETE := "complete"

const INITIAL_PASSWORD := "alex"
const FINAL_PASSWORD   := "ciberacoso"

# ── Apps y etapa minima requerida ───────────────────────────
# Construido en _init() con HashMap propio
var APP_UNLOCK_STAGE: HashMap

# ── Textos de ayuda por etapa ────────────────────────────────
var _help_texts: HashMap

# ── Estado y bus ────────────────────────────────────────────
var state: GameState
var bus:   EventBus

var _stage_order: ArrayList

func _init() -> void:
	state = GameState.new()
	bus   = EventBus.new()

	_stage_order = ArrayList.new()
	_stage_order.append(STAGE_LOCKED)
	_stage_order.append(STAGE_INTRO)
	_stage_order.append(STAGE_MIDWAY)
	_stage_order.append(STAGE_ADVANCED)
	_stage_order.append(STAGE_FINAL)
	_stage_order.append(STAGE_COMPLETE)

	APP_UNLOCK_STAGE = HashMap.new()
	APP_UNLOCK_STAGE.put("mensajes",   STAGE_INTRO)
	APP_UNLOCK_STAGE.put("archivos",   STAGE_INTRO)
	APP_UNLOCK_STAGE.put("galeria",    STAGE_INTRO)
	APP_UNLOCK_STAGE.put("buscador",   STAGE_INTRO)
	APP_UNLOCK_STAGE.put("red_social", STAGE_MIDWAY)
	APP_UNLOCK_STAGE.put("notas",      STAGE_MIDWAY)
	APP_UNLOCK_STAGE.put("diario",     STAGE_COMPLETE)

	_help_texts = HashMap.new()
	_help_texts.put(STAGE_LOCKED,
		"AYUDA - Bloqueo\nEl telefono esta bloqueado.\nLa carta contiene la clave. Interpretala.")
	_help_texts.put(STAGE_INTRO,
		"AYUDA - Primera etapa\nExplora: Mensajes, Archivos, Galeria, Buscador.\nBusca letras resaltadas en el archivo de Alex.")
	_help_texts.put(STAGE_MIDWAY,
		"AYUDA - Segunda etapa\nRed Social y Notas ya disponibles.\nUn perfil del buscador es distinto. Usa el cifrado Cesar.")
	_help_texts.put(STAGE_ADVANCED,
		"AYUDA - Tercera etapa\nUn apodo ofensivo aparece censurado.\nIdentifica el patron y reconstruye la palabra.")
	_help_texts.put(STAGE_FINAL,
		"AYUDA - Contrasena final\nUne las 3 pistas para formar la contrasena.")
	_help_texts.put(STAGE_COMPLETE,
		"El diario de Alex esta desbloqueado. Lee su historia.")

# ── Utilitarios internos ─────────────────────────────────────
func _stage_idx(s: String) -> int:
	return _stage_order.index_of(s)

func _pub(event: String, kv: Dictionary = {}) -> void:
	var d := HashMap.new()
	for k in kv:
		d.put(k, kv[k])
	bus.publish(event, d)

# ════════════════════════════════════════════════════════════
# T9 / T13 — Desbloqueo del telefono
# ════════════════════════════════════════════════════════════
func unlock_phone(password: String) -> bool:
	state.clear_messages()
	if password.strip_edges() == "":
		var msg := "Debes ingresar una contrasena."
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "unlock"})
		return false
	if password.strip_edges().to_lower() == INITIAL_PASSWORD:
		state.get_tracker().advance_stage(STAGE_INTRO)
		_pub("phone_unlocked", {"stage": STAGE_INTRO})
		_pub("stage_changed",  {"new_stage": STAGE_INTRO})
		return true
	var msg := state.rand_wrong_pwd()
	state.set_error(msg)
	_pub("error_occurred", {"message": msg, "source": "unlock"})
	return false

# ════════════════════════════════════════════════════════════
# T8 — Navegacion entre apps
# ════════════════════════════════════════════════════════════
func open_app(app_name: String) -> bool:
	state.clear_messages()
	if state.get_stage() == STAGE_LOCKED:
		var msg := "Primero desbloquea el telefono."
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "nav"})
		return false
	if not APP_UNLOCK_STAGE.contains_key(app_name):
		var msg := "La app '%s' no existe." % app_name
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "nav"})
		return false
	var req: String = APP_UNLOCK_STAGE.get_val(app_name)
	if _stage_idx(state.get_stage()) < _stage_idx(req):
		var msg := "'%s' no disponible todavia." % app_name
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "nav"})
		return false
	state.set_current_app(app_name)
	_pub("app_opened", {"app": app_name})
	return true

func go_home() -> void:
	var prev := state.get_current_app()
	state.set_current_app("")
	state.clear_messages()
	_pub("app_closed", {"previous_app": prev})

func close_app() -> void:
	go_home()

# ════════════════════════════════════════════════════════════
# T12 — Apps disponibles segun progreso
# ════════════════════════════════════════════════════════════
func get_available_apps() -> ArrayList:
	var out := ArrayList.new()
	var cur := _stage_idx(state.get_stage())
	var app_keys := APP_UNLOCK_STAGE.keys()
	for i in range(app_keys.size()):
		var app: String = app_keys.get_at(i)
		var req: String = APP_UNLOCK_STAGE.get_val(app)
		if cur >= _stage_idx(req):
			out.append(app)
	return out

func is_app_unlocked(app_name: String) -> bool:
	if not APP_UNLOCK_STAGE.contains_key(app_name):
		return false
	var req: String = APP_UNLOCK_STAGE.get_val(app_name)
	return _stage_idx(state.get_stage()) >= _stage_idx(req)

# ════════════════════════════════════════════════════════════
# T16 — Validacion de puzzles / pistas
# ════════════════════════════════════════════════════════════
func submit_puzzle_answer(clue_key: String, answer: String) -> bool:
	state.clear_messages()
	var puzzle: Puzzle = state.get_puzzle_by_clue(clue_key)
	if puzzle == null:
		var msg := "Puzzle '%s' no reconocido." % clue_key
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "puzzle"})
		return false
	if answer.strip_edges() == "":
		var msg := "Debes ingresar una respuesta."
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "puzzle"})
		return false
	if state.get_tracker().has_clue(clue_key):
		state.set_feedback("Ya tienes esta pista!")
		return true
	if puzzle.check_answer(answer):
		state.get_tracker().collect_clue(clue_key, answer.strip_edges())
		state.set_feedback(state.rand_motivational())
		_pub("clue_collected", {
			"clue_key": clue_key,
			"value":    answer.strip_edges(),
			"total":    state.get_tracker().collected_count()
		})
		_advance()
		return true
	var hint := puzzle.get_random_hint()
	var msg  := "Incorrecto. Pista: " + hint
	state.set_error(msg)
	_pub("error_occurred", {"message": msg, "source": "puzzle"})
	return false

func _advance() -> void:
	var n := state.get_tracker().collected_count()
	var c := state.get_stage()
	var ns := ""
	if   n == 1 and c == STAGE_INTRO:    ns = STAGE_MIDWAY
	elif n == 2 and c == STAGE_MIDWAY:   ns = STAGE_ADVANCED
	elif n == 3 and c == STAGE_ADVANCED: ns = STAGE_FINAL
	if ns != "":
		state.get_tracker().advance_stage(ns)
		_pub("stage_changed", {"new_stage": ns})

# ════════════════════════════════════════════════════════════
# T14 — Contrasena final
# ════════════════════════════════════════════════════════════
func submit_final_password(password: String) -> bool:
	state.clear_messages()
	if state.get_stage() != STAGE_FINAL:
		var msg := "Aun no tienes todas las pistas."
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "final"})
		return false
	if password.strip_edges() == "":
		var msg := "Ingresa la contrasena final."
		state.set_error(msg)
		_pub("error_occurred", {"message": msg, "source": "final"})
		return false
	if password.strip_edges().to_lower() == FINAL_PASSWORD:
		state.get_tracker().advance_stage(STAGE_COMPLETE)
		state.set_feedback("Lo lograste! El diario esta desbloqueado.")
		_pub("game_complete",  {"stage": STAGE_COMPLETE})
		_pub("stage_changed",  {"new_stage": STAGE_COMPLETE})
		return true
	var msg := "Contrasena incorrecta. Revisa tus pistas."
	state.set_error(msg)
	_pub("error_occurred", {"message": msg, "source": "final"})
	return false

# ════════════════════════════════════════════════════════════
# AYUDA — Requisito Usabilidad
# ════════════════════════════════════════════════════════════
func request_help() -> String:
	var stage := state.get_stage()
	var text: String = _help_texts.get_val(stage, "Explora el telefono.")
	_pub("help_requested", {"stage": stage})
	return text

func get_puzzle_hint(clue_key: String) -> String:
	var p: Puzzle = state.get_puzzle_by_clue(clue_key)
	if p == null:
		return "Sin pistas adicionales."
	return p.get_random_hint()

# ════════════════════════════════════════════════════════════
# T11 — Consultas de estado
# ════════════════════════════════════════════════════════════
func is_phone_locked()     -> bool: return state.get_stage() == STAGE_LOCKED
func is_game_complete()    -> bool: return state.get_stage() == STAGE_COMPLETE
func is_final_lock_active() -> bool: return state.get_stage() == STAGE_FINAL
func get_stage()           -> String: return state.get_stage()
func get_state_summary()   -> HashMap: return state.full_summary()

# ════════════════════════════════════════════════════════════
# T10 — Pistas recolectadas
# ════════════════════════════════════════════════════════════
func get_collected_clues() -> HashMap:
	var out  := HashMap.new()
	var vals := state.get_tracker().all_clues()
	for i in range(vals.size()):
		var c: Clue = vals.get_at(i)
		if c.is_collected():
			out.put(c.get_key(), c.get_value())
	return out

func has_clue(clue_key: String) -> bool:
	return state.get_tracker().has_clue(clue_key)

# ════════════════════════════════════════════════════════════
# Observer — para UI y apps
# ════════════════════════════════════════════════════════════
func subscribe(event_name: String, callable: Callable) -> void:
	bus.subscribe(event_name, callable)

func unsubscribe(event_name: String, callable: Callable) -> void:
	bus.unsubscribe(event_name, callable)
