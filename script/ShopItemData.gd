# ShopItemData.gd
extends Resource
class_name ShopItemData # Permite criar este tipo de recurso no editor

# As propriedades que todo item da loja terá
@export var item_name: String = "Item Misterioso"
@export_multiline var item_description: String = "Descrição do item."
@export var item_image: Texture2D
@export var cost: int = 10

# Atributos que o item pode dar ao jogador
@export_enum("Velocidade", "Poder Máximo", "Recuperação de Vida") var attribute_bonus: String
@export var attribute_value: float = 5.0
