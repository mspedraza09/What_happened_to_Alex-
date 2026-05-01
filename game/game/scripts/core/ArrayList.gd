# ArrayList.gd
# Arreglo dinamico manual — equivalente a ArrayList de Python.
# No depende de ninguna estructura nativa de Godot.
# Uso: var arr = ArrayList.new()

class_name ArrayList

var _data: Array = []   # Array de Godot solo como contenedor base
var _size: int = 0

func _init() -> void:
	_data.resize(8)
	_size = 0

func append(val) -> void:
	if _size >= _data.size():
		_data.resize(_data.size() * 2)
	_data[_size] = val
	_size += 1

func get_at(idx: int):
	_check(idx)
	return _data[idx]

func set_at(idx: int, val) -> void:
	_check(idx)
	_data[idx] = val

func remove_value(val) -> bool:
	for i in range(_size):
		if _data[i] == val:
			for j in range(i, _size - 1):
				_data[j] = _data[j + 1]
			_data[_size - 1] = null
			_size -= 1
			return true
	return false

func contains(val) -> bool:
	for i in range(_size):
		if _data[i] == val:
			return true
	return false

func index_of(val) -> int:
	for i in range(_size):
		if _data[i] == val:
			return i
	return -1

func size() -> int:
	return _size

func is_empty() -> bool:
	return _size == 0

func _check(idx: int) -> void:
	if idx < 0 or idx >= _size:
		push_error("ArrayList: indice %d fuera de rango (size=%d)" % [idx, _size])

func toString() -> String:
	var s := "ArrayList["
	for i in range(_size):
		s += str(_data[i])
		if i < _size - 1:
			s += ", "
	return s + "]"
