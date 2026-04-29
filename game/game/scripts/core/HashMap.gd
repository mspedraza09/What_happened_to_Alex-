# HashMap.gd
# Tabla hash con encadenamiento manual.
# No usa Dictionary de Godot.
# Uso: var map = HashMap.new()

class_name HashMap

# Nodo interno para encadenamiento
class _Node:
	var key
	var val
	var next: _Node

	func _init(k, v) -> void:
		key  = k
		val  = v
		next = null

const _INIT_BUCKETS := 16
const _MAX_LOAD     := 0.75

var _buckets: Array  # Array de _Node
var _n_buckets: int
var _size: int

func _init() -> void:
	_n_buckets = _INIT_BUCKETS
	_buckets   = []
	_buckets.resize(_n_buckets)
	_size      = 0

# ── Hash djb2 ───────────────────────────────────────────────
func _hash(key) -> int:
	var h: int = 5381
	for ch in str(key):
		h = ((h << 5) + h + ch.unicode_at(0)) & 0xFFFFFFFF
	return h % _n_buckets

# ── Operaciones principales ─────────────────────────────────
func put(key, val) -> void:
	if float(_size) / float(_n_buckets) >= _MAX_LOAD:
		_rehash()
	var idx  := _hash(key)
	var node: _Node = _buckets[idx]
	while node != null:
		if node.key == key:
			node.val = val
			return
		node = node.next
	var new_node := _Node.new(key, val)
	new_node.next = _buckets[idx]
	_buckets[idx] = new_node
	_size += 1

func get_val(key, default = null):
	var node: _Node = _buckets[_hash(key)]
	while node != null:
		if node.key == key:
			return node.val
		node = node.next
	return default

func remove(key) -> bool:
	var idx  := _hash(key)
	var node: _Node = _buckets[idx]
	var prev: _Node = null
	while node != null:
		if node.key == key:
			if prev != null:
				prev.next = node.next
			else:
				_buckets[idx] = node.next
			_size -= 1
			return true
		prev = node
		node = node.next
	return false

func contains_key(key) -> bool:
	var node: _Node = _buckets[_hash(key)]
	while node != null:
		if node.key == key:
			return true
		node = node.next
	return false

func keys() -> ArrayList:
	var out := ArrayList.new()
	for i in range(_n_buckets):
		var node: _Node = _buckets[i]
		while node != null:
			out.append(node.key)
			node = node.next
	return out

func values() -> ArrayList:
	var out := ArrayList.new()
	for i in range(_n_buckets):
		var node: _Node = _buckets[i]
		while node != null:
			out.append(node.val)
			node = node.next
	return out

func size() -> int:
	return _size

func is_empty() -> bool:
	return _size == 0

func _rehash() -> void:
	var old_b   := _buckets
	var old_n   := _n_buckets
	_n_buckets  *= 2
	_buckets     = []
	_buckets.resize(_n_buckets)
	_size        = 0
	for i in range(old_n):
		var node: _Node = old_b[i]
		while node != null:
			put(node.key, node.val)
			node = node.next

func toString() -> String:
	var s := "HashMap{"
	var first := true
	for i in range(_n_buckets):
		var node: _Node = _buckets[i]
		while node != null:
			if not first:
				s += ", "
			s += str(node.key) + ": " + str(node.val)
			first = false
			node = node.next
	return s + "}"
