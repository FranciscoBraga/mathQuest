# shop_screen.gd
extends Panel

# 1. NOME DO SINAL CORRIGIDO: Um nome simples e claro que descreve a intenção.
signal close_requested
signal item_purchased(item_data) # Avisa ao GameManager que a compra foi um sucesso
# A referência ao botão está correta.
@onready var close_shop_button: Button = $CloseShopButton
@onready var item_list_container: VBoxContainer = %ItemListContainer
@onready var gold_label: Label = %GoldLabel

@export var puzzle_ui: Panel

# --- A LISTA DE ITENS À VENDA ---
# Arraste todos os seus arquivos .tres de itens para esta lista no Inspetor
@export var items_for_sale: Array[ShopItemData]

var item_being_purchased: ShopItemData

func _ready():
	# 2. Conecta o sinal "pressed" do botão a uma função DENTRO deste script.
	#    O nome da função agora segue a convenção da Godot.
	close_shop_button.pressed.connect(_on_close_button_pressed)
	puzzle_ui.answer_chosen.connect(_on_purchase_puzzle_answered)
	populate_shop()
# Preenche a loja com os itens da lista
func populate_shop():
	print("Iniciando populate_shop. Itens para vender: ", items_for_sale.size())
	
	print("A referência ao ItemListContainer é: ", item_list_container)
	if not is_instance_valid(item_list_container):
		print("ERRO CRÍTICO: item_list_container não foi encontrado!")
		return
	
	var slot_scene = preload("res://scenes/shop_item_slot.tscn") # Mude o caminho!
	
	# Limpa a lista antiga antes de adicionar novos itens, para evitar duplicatas
	for child in item_list_container.get_children():
		child.queue_free()
		
	for item_data in items_for_sale:
		var slot_instance = slot_scene.instantiate()
# 1. PRIMEIRO, adicione a instância à árvore da cena.
		#    Isso garante que a função _ready() do slot seja executada
		#    e todas as suas variáveis @onready sejam preenchidas.
		item_list_container.add_child(slot_instance)

		# 2. SÓ DEPOIS, chame a função para configurar os dados.
		#    Agora, as variáveis de label dentro do slot não estarão mais nulas.
		slot_instance.display_item(item_data)
		
		# A conexão do sinal também deve vir depois.
		slot_instance.purchase_attempted.connect(_on_purchase_attempted)

# Chamado quando o jogador responde ao puzzle de compra
func _on_purchase_puzzle_answered(chosen_answer):
	puzzle_ui.hide()
	var correct_change = SettingsManager.gold - item_being_purchased.cost
	
	if chosen_answer == correct_change:
		# SUCESSO!
		print("Compra bem-sucedida!")
		emit_signal("item_purchased", item_being_purchased)
	else:
		# ERRO!
		print("Cálculo incorreto! Compra cancelada.")

# Chamado quando o jogador clica em "Comprar" em qualquer item
func _on_purchase_attempted(item_data: ShopItemData):
	item_being_purchased = item_data
	var player_gold = SettingsManager.gold # Assumindo que o ouro está no SettingsManager/Player
	
	if player_gold < item_data.cost:
		print("Ouro insuficiente!")
		return
	
	# --- O QUEBRA-CABEÇA MATEMÁTICO ---
	var correct_change = player_gold - item_data.cost
	var question = "Você tem %d de ouro. O item custa %d. Com quanto você fica?" % [player_gold, item_data.cost]
	
	# Reutiliza nossa UI de puzzle para a compra!
	var problem = {
		"question": question,
		"correct_answer": correct_change,
		# Gera respostas erradas próximas do troco certo
		"wrong_answers": [correct_change + 10, correct_change - 5, correct_change + 2]
	}
	puzzle_ui.show_puzzle(problem)
# 3. Esta função é chamada pelo botão. Seu único trabalho é emitir o sinal da tela.
func _on_close_button_pressed():
	print("Botão de fechar a loja foi pressionado. Emitindo sinal 'close_requested'...")
	# Emitimos nosso sinal personalizado e bem nomeado.
	emit_signal("close_requested")
	
func open_shop():
	# Atualiza a quantidade de ouro toda vez que a loja é aberta
	gold_label.text = "Ouro: " + str(SettingsManager.gold) # Assumindo que o ouro está no SettingsManager
	show()
