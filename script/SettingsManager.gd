# SettingsManager.gd
extends Node

const SAVE_PATH = "user://settings.cfg"

# Valores padrão
var volume_db = 0.0
var difficulty_level = 1 # 1-Fácil, 2-Médio, etc.
var progression_mode = "Progressivo" # "Progressivo" ou "Aleatório"
var active_operations = {"soma": true, "subtracao": true, "multiplicacao": false, "divisao": false}
var health = 0
var power = 0
var gold = 0

func _ready():
	load_settings()

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "volume_db", volume_db)
	config.set_value("game", "difficulty", difficulty_level)
	config.set_value("game", "progression_mode", progression_mode)
	config.set_value("game", "operations", active_operations)
	config.set_value("player","health",health)
	config.set_value("player","power",power)
	config.set_value("player","gold",gold)
	config.save(SAVE_PATH)
	print("Configurações salvas!")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		print("Arquivo de configurações não encontrado. Usando padrões.")
		return

	volume_db = config.get_value("audio", "volume_db", 0.0)
	difficulty_level = config.get_value("game", "difficulty", 1)
	progression_mode = config.get_value("game", "progression_mode", "Progressivo")
	active_operations = config.get_value("game", "operations", {"soma": true, "subtracao": true, "multiplicacao": false, "divisao": false})

	# Aplica o volume carregado
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	print("Configurações carregadas!")
