extends Panel


signal _on_close_shop_button_pressed

@onready var button_close_shop : Button = $CloseShopButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_close_shop.pressed.connect(close_shop_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func close_shop_button_pressed(delta: float) -> void:
	print("_on_close_shop_button_pressed")
	emit_signal("_on_close_shop_button_pressed")
