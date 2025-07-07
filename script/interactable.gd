# interactable.gd
extends Area2D

# Sinal que avisa ao GameManager que o jogador quer interagir com este objeto
signal interaction_requested(interactable_object)

# Variáveis que TODO objeto interagível terá. Podemos editá-las no Inspetor.
@export var interaction_prompt = "Abrir" # Texto que pode aparecer (ex: "Abrir Baú")
@export_enum("Fácil", "Médio", "Difícil") var difficulty = "Fácil"
@export_range(1, 5) var puzzle_steps = 1 # Quantos cálculos precisa resolver

var player_is_near = false

func _ready():
	# Conecta os sinais da própria Area2D para saber quando o jogador entra/sai
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Função para ser chamada pelo GameManager quando o puzzle for resolvido
func on_interaction_success():
	print("Interação bem-sucedida com ", name)
	# Desativa a colisão para não poder interagir de novo
	$CollisionShape2D.disabled = true
	# Aqui podemos tocar uma animação de "abrir o baú", por exemplo.

func _input(event):
	# Se o jogador está perto E aperta a tecla de interação (ex: "E")
	if player_is_near and event.is_action_pressed("ui_accept"): # "ui_accept" é Enter/Espaço por padrão
		emit_signal("interaction_requested", self)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_is_near = true
		# Futuramente, mostrar um balão com a tecla "E" aqui
		print("Perto de: ", name, ". Pressione Enter para interagir.")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_is_near = false
		# Esconder o balão com a tecla "E"
