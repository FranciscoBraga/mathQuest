# game_over_screen.gd
extends Panel

# Sinal que esta tela emitirá quando o jogador quiser reiniciar.
signal restart_game_requested

@onready var restart_button: Button = $RestartButton

func _ready():
	# Conecta o botão de reiniciar a uma função DENTRO deste script.
	restart_button.pressed.connect(_on_restart_button_pressed)

func _on_restart_button_pressed():
	# Em vez de reiniciar o jogo aqui, nós apenas "anunciamos" a intenção.
	emit_signal("restart_game_requested")
