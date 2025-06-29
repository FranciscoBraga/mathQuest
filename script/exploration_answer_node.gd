# exploration_answer_node.gd
extends Area2D

# Sinal que avisa ao GameManager qual valor foi clicado e ONDE ele estava.
signal choice_made(value, position)

var answer_value = 0

func _ready():
	# Garante que a área seja clicável.
	input_pickable = true

func setup(value: int, spawn_position: Vector2):
	answer_value = value
	global_position = spawn_position
	$Label.text = str(answer_value)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("choice_made", answer_value, global_position)
