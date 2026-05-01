# RandomLCG.gd
# Generador pseudo-aleatorio LCG sin usar randi() de Godot.
# Uso: var rng = RandomLCG.new()

class_name RandomLCG

const _A := 1664525
const _C := 1013904223
const _M := 4294967296  # 2^32

var _state: int

func _init() -> void:
	_state = (Time.get_ticks_msec() * 1000013) % _M

func next_int() -> int:
	_state = (_A * _state + _C) % _M
	return _state

func next_range(low: int, high: int) -> int:
	if high <= low:
		return low
	return low + (next_int() % (high - low))
