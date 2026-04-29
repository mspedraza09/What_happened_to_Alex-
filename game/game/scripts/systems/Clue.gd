# Clue.gd — TAD 1
# Representa una pista del juego.
# Uso: var clue = Clue.new("clue1", "Archivo de trabajo", "Busca letras resaltadas.")

class_name Clue

var _key:       String
var _label:     String
var _hint:      String
var _value:     String
var _collected: bool

func _init(key: String, label: String, hint: String) -> void:
	if key == "" or label == "":
		push_error("Clue: key y label no pueden estar vacios.")
		return
	_key       = key
	_label     = label
	_hint      = hint
	_value     = ""
	_collected = false

func get_key()   -> String: return _key
func get_label() -> String: return _label
func get_hint()  -> String: return _hint
func get_value() -> String: return _value
func is_collected() -> bool: return _collected

func collect(value: String) -> void:
	if value.strip_edges() == "":
		push_error("Clue.collect: valor no puede estar vacio.")
		return
	_value     = value.strip_edges()
	_collected = true

func reset() -> void:
	_value     = ""
	_collected = false

func to_map() -> HashMap:
	var m := HashMap.new()
	m.put("key",       _key)
	m.put("label",     _label)
	m.put("collected", _collected)
	m.put("value",     _value)
	return m

func to_string() -> String:
	var s := "'%s'" % _value if _collected else "pendiente"
	return "Clue(%s, %s)" % [_key, s]
