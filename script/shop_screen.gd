# shop_screen.gd
extends Panel

# 1. NOME DO SINAL CORRIGIDO: Um nome simples e claro que descreve a intenção.
signal close_requested

# A referência ao botão está correta.
@onready var close_shop_button: Button = $CloseShopButton

func _ready():
	# 2. Conecta o sinal "pressed" do botão a uma função DENTRO deste script.
	#    O nome da função agora segue a convenção da Godot.
	close_shop_button.pressed.connect(_on_close_button_pressed)

# 3. Esta função é chamada pelo botão. Seu único trabalho é emitir o sinal da tela.
func _on_close_button_pressed():
	print("Botão de fechar a loja foi pressionado. Emitindo sinal 'close_requested'...")
	# Emitimos nosso sinal personalizado e bem nomeado.
	emit_signal("close_requested")
	
