extends Control
signal chat_seleccionado(nombre)
@export var nombre_usuario: String = "Usuario"
@export var ultimo_mensaje: String = "Hola..."
@export var foto_perfil: Texture2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Label.text = nombre_usuario
	%Label2.text = ultimo_mensaje
	if foto_perfil:
		%FotoRect.texture = foto_perfil


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	# Avisamos que este chat fue tocado
	emit_signal("chat_seleccionado", nombre_usuario)
	
