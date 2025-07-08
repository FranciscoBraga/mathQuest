# MathProblem.gd
extends Node

# Função final e completa para gerar todos os tipos de problemas
func generate_problem(current_game_phase: int, num_wrong_answers_needed: int) -> Dictionary:
	# --- 1. LER AS CONFIGURAÇÕES ATUAIS ---
	var level = SettingsManager.difficulty_level
	var mode = SettingsManager.progression_mode
	var active_ops = SettingsManager.active_operations
	
	# --- 2. DEFINIR A DIFICULDADE (TAMANHO DOS NÚMEROS) ---
	var max_number = 10
	match level:
		1: max_number = 99
		2: max_number = 999
		3: max_number = 9999
		4: max_number = 9999999
	
	var min_number = 1
	if mode == "Progressivo":
		var phase_tier = floor((current_game_phase - 1) / 7)
		if phase_tier == 0: max_number = min(max_number, 9)
		elif phase_tier == 1: max_number = min(max_number, 99)
		else: max_number = min(max_number, 999)
		
	# --- 3. ESCOLHER O TIPO DE PROBLEMA ---
	var problem_types = ["standard"]
	if current_game_phase >= 5: problem_types.append("find_x")
	if current_game_phase >= 10: problem_types.append("greater_less")
	var chosen_problem_type = problem_types.pick_random()

	# --- 4. GERAR O PROBLEMA E A RESPOSTA CORRETA ---
	var question: String
	var correct_answer: int
	
	match chosen_problem_type:
		"standard":
			# Lógica completa para A + B = ?
			var available_ops = []
			for op in active_ops:
				if active_ops[op]: available_ops.append(op)
			if available_ops.is_empty(): available_ops.append("soma")
			
			var chosen_op = available_ops.pick_random()
			var num1: int
			var num2: int
			
			match chosen_op:
				"soma":
					num1 = randi_range(min_number, max_number)
					num2 = randi_range(min_number, max_number)
					correct_answer = num1 + num2
					question = "%d + %d = ?" % [num1, num2]
				"subtracao":
					num1 = randi_range(min_number, max_number)
					num2 = randi_range(min_number, num1)
					correct_answer = num1 - num2
					question = "%d - %d = ?" % [num1, num2]
				"multiplicacao":
					var mult_max = int(sqrt(max_number))
					num1 = randi_range(min_number, mult_max)
					num2 = randi_range(min_number, mult_max)
					correct_answer = num1 * num2
					question = "%d × %d = ?" % [num1, num2]
				"divisao":
					var result = randi_range(2, 25)
					num2 = randi_range(2, 25)
					num1 = result * num2
					correct_answer = result
					question = "%d ÷ %d = ?" % [num1, num2]

		"find_x":
			var num1 = randi_range(min_number, max_number / 2)
			var result = randi_range(num1 + 1, max_number)
			correct_answer = result - num1
			question = "%d + X = %d" % [num1, result]
			
		"greater_less":
			var num1 = randi_range(min_number, 20)
			var num2 = randi_range(min_number, 20)
			var num3 = randi_range(min_number, 20)
			var num4 = randi_range(min_number, 20)
			var result1 = num1 * num2
			var result2 = num3 + num4
			question = "(%d × %d) ___ (%d + %d)" % [num1, num2, num3, num4]
			if result1 > result2: correct_answer = 1 # Usaremos 1 para ">"
			elif result1 < result2: correct_answer = 2 # 2 para "<"
			else: correct_answer = 3 # 3 para "="
	
	# --- 5. GERAR AS RESPOSTAS INCORRETAS ---
	var wrong_answers = []
	if chosen_problem_type == "greater_less":
		var all_possible = [1, 2, 3]
		all_possible.erase(correct_answer)
		wrong_answers = all_possible
	else:
		var offset_range = max(5, int(correct_answer * 0.2))
		while wrong_answers.size() < num_wrong_answers_needed:
			var offset = randi_range(-offset_range, offset_range)
			var new_wrong_answer = correct_answer + offset
			if offset != 0 and new_wrong_answer not in wrong_answers and new_wrong_answer >= 0:
				wrong_answers.append(new_wrong_answer)

	# --- 6. RETORNAR O DICIONÁRIO COMPLETO ---
	return {
		"question": question,
		"correct_answer": correct_answer,
		"wrong_answers": wrong_answers,
		"type": chosen_problem_type
	}
