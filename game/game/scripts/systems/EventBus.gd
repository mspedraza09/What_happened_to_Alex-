# EventBus.gd — TAD 4
# Patron Observer. HashMap<event_name, ArrayList<Callable>>.
# En Godot usamos Callable en lugar de clases abstractas.
#
# Uso desde la UI (ANNY):
#   GameController.subscribe("stage_changed", _on_stage_changed)
#   func _on_stage_changed(data: HashMap) -> void:
#       var nueva_etapa = data.get_val("new_stage")
#
# Eventos publicados:
#   "phone_unlocked"  "app_opened"     "app_closed"
#   "clue_collected"  "stage_changed"  "game_complete"
#   "error_occurred"  "help_requested"

class_name EventBus

# HashMap<String, ArrayList<Callable>>
var _listeners: HashMap

func _init() -> void:
	_listeners = HashMap.new()

func subscribe(event_name: String, callable: Callable) -> void:
	if not _listeners.contains_key(event_name):
		_listeners.put(event_name, ArrayList.new())
	var arr: ArrayList = _listeners.get_val(event_name)
	# Evitar duplicados comparando por nombre de metodo
	for i in range(arr.size()):
		if arr.get_at(i) == callable:
			return
	arr.append(callable)

func unsubscribe(event_name: String, callable: Callable) -> void:
	if _listeners.contains_key(event_name):
		_listeners.get_val(event_name).remove_value(callable)

func publish(event_name: String, data: HashMap = null) -> void:
	if data == null:
		data = HashMap.new()
	if not _listeners.contains_key(event_name):
		return
	var arr: ArrayList = _listeners.get_val(event_name)
	for i in range(arr.size()):
		var cb: Callable = arr.get_at(i)
		if cb.is_valid():
			cb.call(data)
