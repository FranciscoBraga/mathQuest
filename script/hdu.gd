extends Control

# Referências para as barras e para o jogador
# Use @export para arrastar e soltar no inspetor, é mais seguro!
@export var player: CharacterBody2D
@onready var health_bar : TextureProgressBar = $HealthBar
@onready var power_bar: TextureProgressBar = $PowerBar

@onready var gold_label:  Label  = $GoldLabel  # Nova variável

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
	player.gold_changed.connect(_on_player_gold_changed)

	# Configura o valor inicial
	gold_label.text = "Ouro: %d" % player.gold
	
# Nova função para atualizar o label de ouro
func _on_player_gold_changed(new_gold_amount):
	gold_label.text = "Ouro: %d" % new_gold_amount
# Esta função é chamada quando o sinal 'health_changed' é emitido
func _on_player_health_changed(current_health):
	health_bar.value = current_health

# Esta função é chamada quando o sinal 'power_changed' é emitido
func _on_player_power_changed(current_power):
	power_bar.value = current_power
