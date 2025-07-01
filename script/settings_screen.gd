# settings_screen.gd
extends Panel

# Arraste os nós do editor para estes campos no Inspetor
@export var volume_slider: HSlider
@export var difficulty_options: OptionButton
@export var operations_checkboxes: VBoxContainer # Coloque seus checkboxes dentro de um VBoxContainer
@export var progressive_check: CheckButton
@export var random_check: CheckButton

func _ready():
	# Conecta os sinais da UI a funções neste script
	volume_slider.value_changed.connect(_on_volume_changed)
	difficulty_options.item_selected.connect(_on_difficulty_selected)
	progressive_check.toggled.connect(_on_progression_mode_toggled)
	random_check.toggled.connect(_on_progression_mode_toggled)
	for checkbox in operations_checkboxes.get_children():
		checkbox.toggled.connect(_on_operation_toggled)
	
	# Carrega os valores atuais para a UI
	load_values_to_ui()

func load_values_to_ui():
	# Volume (convertendo de dB para valor linear)
	volume_slider.value = db_to_linear(SettingsManager.volume_db)
	
	# Dificuldade
	difficulty_options.select(SettingsManager.difficulty_level - 1)
	
	# Modo de Progressão
	if SettingsManager.progression_mode == "Progressivo":
		progressive_check.button_pressed = true
	else:
		random_check.button_pressed = true
		
	# Operações Ativas
	for checkbox in operations_checkboxes.get_children():
		var op_name = checkbox.name.to_lower()
		checkbox.button_pressed = SettingsManager.active_operations.get(op_name, false)

func _on_volume_changed(value):
	var db = linear_to_db(value)
	SettingsManager.volume_db = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	SettingsManager.save_settings()

func _on_difficulty_selected(index):
	SettingsManager.difficulty_level = index + 1
	# Validação simples baseada na minha sugestão
	validate_operations_for_level()
	SettingsManager.save_settings()
	
func _on_progression_mode_toggled(pressed, button_name):
	# Lógica para garantir que apenas um seja selecionado
	# ...
	SettingsManager.progression_mode = button_name
	SettingsManager.save_settings()

func _on_operation_toggled(pressed, op_name):
	SettingsManager.active_operations[op_name.to_lower()] = pressed
	SettingsManager.save_settings()

func validate_operations_for_level():
	# Exemplo de lógica para habilitar/desabilitar checkboxes com base no nível
	var level = SettingsManager.difficulty_level
	operations_checkboxes.get_node("Multiplicacao").disabled = level < 2
	operations_checkboxes.get_node("Divisao").disabled = level < 3
	# ...
