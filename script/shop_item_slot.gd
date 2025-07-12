# shop_item_slot.gd
extends PanelContainer

# Sinal que avisa à loja qual item o jogador tentou comprar
signal purchase_attempted(item_data)

# Referências para os nós da UI dentro desta cena
@onready var item_name_label: Label = $HBoxContainer/TextInfo/ItemNameLabel
@onready var item_description_label: Label = $HBoxContainer/TextInfo/ItemDescriptionLabel
@onready var item_cost_label: Label = $HBoxContainer/TextInfo/CostContainer/ItemCostLabel
@onready var item_image: TextureRect = $HBoxContainer/ItemImage
@onready var buy_button: Button = $HBoxContainer/TextInfo/BuyButton

var current_item_data: ShopItemData

func _ready():
	buy_button.pressed.connect(_on_buy_button_pressed)

# Esta função preenche a prateleira com os dados de um item
func display_item(data: ShopItemData):
	current_item_data = data
	item_name_label.text = data.item_name
	item_description_label.text = data.item_description
	item_cost_label.text = str(data.cost)
	item_image.texture = data.item_image

func _on_buy_button_pressed():
	# Avisa à tela principal da loja que uma compra foi tentada
	emit_signal("purchase_attempted", current_item_data)
