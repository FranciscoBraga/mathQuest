# MathProblem.gd
extends Node

# A função inteira foi reescrita para seguir a ordem lógica correta.
func generate_problem(current_game_phase: int) -> Dictionary:
	var level = SettingsManager.difficulty_level
	var mode = SettingsManager.progression_mode
	
	# --- 1. Define os Parâmetros da Dificuldade ---
	var max_number = 10
	if level == 1: max_number = 99
	elif level == 2: max_number = 999
	elif level == 3: max_number = 9999
	elif level == 4: max_number = 9999999
	
	var min_number = 1
	if mode == "Progressivo":
		var phase_tier = floor((current_game_phase - 1) / 7)
		if phase_tier == 0: max_number = min(max_number, 9)
		elif phase_tier == 1: max_number = min(max_number, 99)
		elif phase_tier == 2: max_number = min(max_number, 999)

	# --- 2. Escolhe a Operação ---
	var available_ops = []
	for op in SettingsManager.active_operations:
		if SettingsManager.active_operations[op]:
			available_ops.append(op)
	
	# Verificação de segurança: se nenhuma operação for escolhida, usa a soma como padrão
	if available_ops.is_empty():
		available_ops.append("soma")
	
	var chosen_op = available_ops.pick_random()

	# --- 3. Gera os Números e Calcula a Resposta Correta ---
	var num1: int
	var num2: int
	var correct_answer: int
	var question: String
	
	match chosen_op:
		"soma":
			num1 = randi_range(min_number, max_number)
			num2 = randi_range(min_number, max_number)
			correct_answer = num1 + num2
			question = "%d + %d" % [num1, num2]
		"subtracao":
			num1 = randi_range(min_number, max_number)
			num2 = randi_range(min_number, num1) # Garante que num2 seja menor ou igual a num1
			correct_answer = num1 - num2
			question = "%d - %d" % [num1, num2]
		"multiplicacao":
			# Usamos números menores para multiplicação para não explodir o resultado
			var mult_max = sqrt(max_number)
			num1 = randi_range(min_number, mult_max)
			num2 = randi_range(min_number, mult_max)
			correct_answer = num1 * num2
			question = "%d × %d" % [num1, num2]
		"divisao":
			# Lógica especial para garantir resultado inteiro: trabalhamos de trás para frente.
			var result = randi_range(2, 20) # A resposta será um número pequeno
			num2 = randi_range(2, 20)
			num1 = result * num2 # O primeiro número é o resultado da multiplicação
			correct_answer = result
			question = "%d ÷ %d" % [num1, num2]

	# --- 4. Gera as Respostas Incorretas (AGORA que temos a resposta correta) ---
	var wrong_answers = []
	var offset_range = max(5, int(correct_answer * 0.2))

	while wrong_answers.size() < 3:
		var offset = randi_range(-offset_range, offset_range)
		var new_wrong_answer = correct_answer + offset

		if offset != 0 and new_wrong_answer not in wrong_answers and new_wrong_answer >= 0:
			wrong_answers.append(new_wrong_answer)
			
	# --- 5. Retorna o Dicionário Completo ---
	return {
		"question": question,
		"correct_answer": correct_answer,
		"wrong_answers": wrong_answers
	}
