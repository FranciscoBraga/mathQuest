# projectile.gd
extends Area2D

var direction = Vector2.ZERO
var speed = 600

func _physics_process(delta):
	# Move o projétil na sua direção
	position += direction * speed * delta

# Conecte o sinal "body_entered" da Area2D a esta função
func _on_body_entered(body):
	# PRIMEIRO, IGNORA A COLISÃO COM O PRÓPRIO JOGADOR
	# Isso evita que o projétil se destrua no momento em que é criado.
	if body.is_in_group("player"):
		return # Ignora o resto da função

	# SEGUNDO, VERIFICA SE ATINGIU UM INIMIGO
	if body.is_in_group("enemies"):
		# Se sim, causa dano ao inimigo.
		# A verificação 'has_method' é uma segurança extra.
		if body.has_method("take_damage"):
			body.take_damage(50) # Causa 50 de dano

	# TERCEIRO, INDEPENDENTEMENTE DO QUE ATINGIU (inimigo, parede, etc.),
	# o projétil se destrói. Como já ignoramos o jogador no início,
	# nunca se destruirá ao tocar nele.
	queue_free()
