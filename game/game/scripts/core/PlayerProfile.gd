# PlayerProfile.gd
# TAD 9 — Perfil de un jugador.
#
# Representa a un jugador registrado en el sistema.
# Guarda su nombre, cuando fue creado y su ultimo progreso.
#
# Formato en el indice de perfiles (players.idx):
#   PLAYER:alejandro:2026-05-01
#   PLAYER:maria:2026-05-02
#   END

class_name PlayerProfile

var username:    String   # identificador unico, sin espacios
var display_name: String  # nombre que se muestra en pantalla
var created_at:  String   # fecha de creacion "YYYY-MM-DD"
var last_played: String   # ultima vez que jugo

func _init(uname: String, dname: String, created: String) -> void:
	if uname.strip_edges() == "":
		push_error("PlayerProfile: username no puede estar vacio.")
		return
	username     = uname.strip_edges().to_lower()
	display_name = dname.strip_edges()
	created_at   = created
	last_played  = created

func get_save_path() -> String:
	# Cada jugador tiene su propio archivo de guardado
	return "user://save_%s.sav" % username

func to_string() -> String:
	return "PlayerProfile(%s)" % username
