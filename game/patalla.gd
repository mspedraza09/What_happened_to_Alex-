extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Recorremos todos los chats que hay en el contenedor
	for chat in $AppMensaje/ScrollContainer/VBoxContainer.get_children():
		chat.connect("chat_seleccionado", _ir_al_chat)
	pass # Replace with function body.
func _ir_al_chat(nombre_del_usuario):
	print("Abriendo chat con: ", nombre_del_usuario)
	# Aquí es donde ocurre la magia del cambio de pantalla
	get_tree().change_scene_to_file("res://escena_de_conversacion.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
