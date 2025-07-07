# settings_screen.gd
extends Panel

# Arraste os nós do editor para estes campos no Inspetor
@onready var volume_slider: HSlider = $HSlider
@onready var difficulty_options: OptionButton = $OptionButton
@onready var operations_checkboxes: VBoxContainer  = $VBoxContainer# Coloque seus checkboxes dentro de um VBoxContainer
@onready var progressive_check: CheckButton = $progressiveCheck 
@onready var random_check: CheckButton = $randomCheck 
@onready var close_button: Button = $Fechar

signal close_settings

func _ready():
	# Conecta os sinais da UI a funções neste script
	volume_slider.value_changed.connect(_on_volume_changed)
	difficulty_options.item_selected.connect(_on_difficulty_selected)
# Nós "empacotamos" o nome do modo junto com a conexão.
	progressive_check.toggled.connect(_on_progression_mode_toggled.bind("Progressivo"))
	random_check.toggled.connect(_on_progression_mode_toggled.bind("Aleatório"))
	close_button.pressed.connect(_on_close_button_settings)
	
	# Para cada checkbox de operação dentro do container...
	for checkbox in operations_checkboxes.get_children():
		# Conectamos o sinal 'toggled', e usamos .bind() para passar o NOME do próprio checkbox como um argumento extra.
		checkbox.toggled.connect(_on_operation_toggled.bind(checkbox.name))
	
	
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
	
# A função agora espera o 'pressed' (bool) do sinal e o 'mode_name' (String) que nós empacotamos com bind.
func _on_progression_mode_toggled(pressed: bool, mode_name: String):
	# Nós só queremos agir quando um botão é MARCADO (pressed = true)
	if pressed:
		print("Modo de progressão mudou para: ", mode_name)
		SettingsManager.progression_mode = mode_name
		
		# Lógica para garantir que apenas um botão fique marcado (efeito de "radio button")
		if mode_name == "Progressivo":
			# Desmarca o outro botão sem causar um loop infinito de sinais,
			# pois a outra chamada emitirá toggled(false), que será ignorado pelo nosso 'if pressed'.
			random_check.button_pressed = false
		else: # Se o modo for "Aleatório"
			progressive_check.button_pressed = false
			
		# Salva a nova configuração
		SettingsManager.save_settings()

func _on_operation_toggled(pressed: bool, op_name: String):
	# O nome da operação (ex: "Soma") agora é recebido corretamente.
	print("Operação '", op_name, "' foi alterada para: ", pressed)
	
	# Atualiza o dicionário no nosso gerenciador de configurações.
	# Usamos to_lower() para garantir consistência (ex: "Soma" vira "soma").
	SettingsManager.active_operations[op_name.to_lower()] = pressed
	SettingsManager.save_settings()

func validate_operations_for_level():
	# Exemplo de lógica para habilitar/desabilitar checkboxes com base no nível
	var level = SettingsManager.difficulty_level
	operations_checkboxes.get_node("Multiplicacao").disabled = level < 2
	operations_checkboxes.get_node("Divisao").disabled = level < 3
	# ...
func _on_close_button_settings():
	print("close settings")
	emit_signal("close_settings")
	
	
