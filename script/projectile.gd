# projectile.gd
extends Area2D

var direction = Vector2.ZERO
var speed = 600

func _physics_process(delta):
	# Move o projétil na sua direção
	position += direction * speed * delta

# Conecte o sinal "body_entered" da Area2D a esta função
func _on_body_entered(body):
	# Verifica se o corpo que atingiu é um inimigo
	if body.is_in_group("enemies"): # <-- IMPORTANTE: Adicione seus inimigos a este grupo!
		body.take_damage(50) # Causa 
	
	# O projétil se destrói ao atingir qualquer coisa (exceto o jogador)
	if not body.is_in_group("player"):
		queue_free()
