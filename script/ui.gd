# ui.gd
extends CanvasLayer

# Referências para as barras e para o jogador
# Use @export para arrastar e soltar no inspetor, é mais seguro!
@export var player: CharacterBody2D
@export var health_bar: TextureProgressBar
@export var power_bar: TextureProgressBar

func _ready():
	# Conecta este script aos sinais do jogador
	   # Adicione uma verificação para evitar que o jogo quebre
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.power_changed.connect(_on_player_power_changed)
	# Configura os valores iniciais das barras quando o jogo começa
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	
	power_bar.max_value = player.max_power
	power_bar.value = player.current_power

# Esta função é chamada quando o sinal 'health_changed' é emitido
func _on_player_health_changed(current_health):
	health_bar.value = current_health

# Esta função é chamada quando o sinal 'power_changed' é emitido
func _on_player_power_changed(current_power):
	power_bar.value = current_power
