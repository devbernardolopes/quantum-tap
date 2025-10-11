extends Node

var player_quanta_spent: int = 0
var player_quanta_generated: int = 0
var player_quanta_per_second: int = 0
var elapsed_timer: int = 0

var is_game_paused: bool = false
var current_level: int = 0
var cascade_levels: Array = []

var last_quanta: int = 0

var _quanta_internal: int = 0

var quanta: int:
	get:
		return _quanta_internal
	set(value):
		if _quanta_internal == value:
			return
		_quanta_internal = value
		emit_signal("quanta_changed", value)

var is_sound_on: bool = true
var is_music_on: bool = true

var music_last_position: float = 0.0
var last_beat_index: int = 0

var last_h_scrollbar_value: float = 0.0

var quanta_per_tap: int = 1
var quanta_per_second: int = 0
var multiplier: float = 1.0
var quanta_accumulator: float = 0.0
var cascade_progress: float = 0.0
var cascade_threshold: float = Globals.MIN_CASCADE_THRESHOLD

var has_character_video_pre_cascade_played_this_cascade: bool = false

var has_character_video_particle_accelerator_info_played: bool = false
var play_character_video_particle_accelerator_info: bool = false
var has_character_video_quantum_stabilizer_info_played: bool = false
var play_character_video_quantum_stabilizer_info: bool = false
var has_character_video_dimensional_shift_info_played: bool = false
var play_character_video_dimensional_shift_info: bool = false
var has_character_video_entanglement_array_info_played: bool = false
var play_character_video_entanglement_array_info: bool = false

var upgrades: Dictionary = {
	Globals.ACCELERATOR_ID: {"initial_cost": Globals.ACCELERATOR_INITIAL_COST, "cost": Globals.ACCELERATOR_COST, "level": Globals.ACCELERATOR_LEVEL, "max_level": Globals.ACCELERATOR_MAX_LEVEL, "effect": func(): quanta_per_tap += 1},
	Globals.STABILIZER_ID: {"initial_cost": Globals.STABILIZER_INITIAL_COST, "cost": Globals.STABILIZER_COST, "level": Globals.STABILIZER_LEVEL, "max_level": Globals.STABILIZER_MAX_LEVEL, "effect": func(): quanta_per_second += 1},
	Globals.SHIFT_ID: {"initial_cost": Globals.SHIFT_INITIAL_COST, "cost": Globals.SHIFT_COST, "level": Globals.SHIFT_LEVEL, "max_level": Globals.SHIFT_MAX_LEVEL, "effect": func(): multiplier *= 2},
	Globals.ENTANGLEMENT_ID: {"initial_cost": Globals.ENTANGLEMENT_INITIAL_COST, "cost": Globals.ENTANGLEMENT_COST, "level": Globals.ENTANGLEMENT_LEVEL, "max_level": Globals.ENTANGLEMENT_MAX_LEVEL, "effect": func(): pass}
}

signal game_state_updated
signal quanta_changed(new_value: int)
signal pause_state_changed

var quanta_per_second_timer: Timer = null
var game_timer: Timer = null

var has_reached_goal: bool = false

func has_savegame() -> bool:
	var result: bool = true

	var config = ConfigFile.new()
	var error = config.load("user://savegame.cfg")
	if error != OK:
		result = false

	return result

func _ready() -> void:
	quanta_per_second_timer = Timer.new()
	quanta_per_second_timer.wait_time = 1.0
	quanta_per_second_timer.timeout.connect(_on_quanta_per_second_timer_timeout)
	add_child(quanta_per_second_timer)
	quanta_per_second_timer.start()

	if !has_savegame():
		reset_game()
		#cascade_levels = divide_goal(Globals.QUANTA_GOAL, Globals.QUANTA_LEVELS)
		#set_progress_bar_max_value(cascade_levels[current_level])
		#elapsed_timer = 0
	else:
		load_game()

	game_timer = Timer.new()
	game_timer.wait_time = 1.0
	game_timer.timeout.connect(_on_elapsed_timer_timeout)
	add_child(game_timer)
	game_timer.start()
	
	set_is_game_paused(false)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if quanta < Globals.QUANTA_GOAL:
		has_reached_goal = false
	else:
		if !has_reached_goal:
			has_reached_goal = true
			save_high_score()
			quanta = Globals.QUANTA_GOAL

	#if quanta_per_second > 0:
		## Accumulate fractional Quanta
		#quanta_accumulator += quanta_per_second * delta * multiplier
		## Add whole Quanta when accumulator reaches 1 or more
		#if quanta_accumulator >= 1.0:
			#var whole_quanta = int(quanta_accumulator)
			#quanta += whole_quanta
			#quanta_accumulator -= whole_quanta

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if !has_reached_goal:
			save_game()

func get_random_entanglement_quanta() -> int:
	var result: int = 0
	if upgrades.has("entanglement") and upgrades.entanglement.level > 0:
			var chance = clamp(0.05 + upgrades.entanglement.level * 0.02, 0.0, 1.0)
			if randf() < chance:
				result += int(randi_range(upgrades.entanglement.level, upgrades.entanglement.level + 10) * multiplier)

	return result

func add_quanta(amount: int) -> void:
	var real_amount: int = 0
	if !is_game_paused:
		if !has_reached_goal:
			real_amount = int(amount * multiplier) + get_random_entanglement_quanta()
			player_quanta_generated += real_amount
			quanta += real_amount
			cascade_progress += amount
			print(str(amount) + " " + str(real_amount))
			if cascade_progress >= cascade_threshold:
				trigger_cascade()

func get_upgrade_cost(current_cost: float, level: int, max_level: int, base_cost: float) -> int:
	var growth := base_cost * Globals.UPGRADE_COST_GROWTH
	var exponent := Globals.UPGRADE_EXPONENT + (6.0 / max_level)
	var scale := 1.0 + (max_level / 25.0)
	return int(current_cost + growth * pow(level + 1, exponent) / scale)

func purchase_upgrade(upgrade_id: String) -> bool:
	if has_reached_goal:
		return false
	var upgrade = upgrades[upgrade_id]
	if quanta >= upgrade.cost:
		quanta -= upgrade.cost
		player_quanta_spent += upgrade.cost
		upgrade.level = min(upgrade.level + 1, upgrade.max_level)
		upgrade.cost = get_upgrade_cost(upgrade.cost, upgrade.level, upgrade.max_level, upgrade.initial_cost)
		upgrade.effect.call()
		return true
	return false

func trigger_cascade() -> void:
	if !has_reached_goal:
		var bonus = quanta * (1.0 + upgrades.accelerator.level * 0.1)
		quanta += int(bonus)
		cascade_progress = 0.0
		current_level += 1
		#cascade_threshold *= Globals.CASCADE_THRESHOLD_MULTIPLIER
		cascade_threshold = cascade_levels[current_level]
		#cascade_threshold = min(cascade_threshold, Globals.MAX_CASCADE_THRESHOLD)
		set_progress_bar_max_value(cascade_threshold)
		has_character_video_pre_cascade_played_this_cascade = false

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("game" , "player_quanta_generated", player_quanta_generated)
	config.set_value("game" , "player_quanta_spent", player_quanta_spent)
	config.set_value("game" , "player_quanta_per_second", player_quanta_per_second)
	config.set_value("game" , "elapsed_timer", elapsed_timer)
	config.set_value("game" , "cascade_levels", cascade_levels)
	config.set_value("game" , "current_level", current_level)
	config.set_value("game" , "is_sound_on", is_sound_on)
	config.set_value("game" , "is_music_on", is_music_on)
	config.set_value("game" , "music_last_position", music_last_position)
	config.set_value("game" , "last_beat_index", last_beat_index)
	config.set_value("game" , "last_h_scrollbar_value", last_h_scrollbar_value)
	config.set_value("game" , "quanta", quanta)
	config.set_value("game", "quanta_per_tap", quanta_per_tap)
	config.set_value("game", "quanta_per_second", quanta_per_second)
	config.set_value("game", "multiplier", multiplier)
	config.set_value("game", "cascade_progress", cascade_progress)
	config.set_value("game", "cascade_threshold", cascade_threshold)
	config.set_value("game", "quanta_accumulator", quanta_accumulator)
	config.set_value("game", "has_character_video_pre_cascade_played_this_cascade", has_character_video_pre_cascade_played_this_cascade)
	config.set_value("game", "has_character_video_particle_accelerator_info_played", has_character_video_particle_accelerator_info_played)
	config.set_value("game", "play_character_video_particle_accelerator_info", play_character_video_particle_accelerator_info)
	config.set_value("game", "has_character_video_quantum_stabilizer_info_played", has_character_video_quantum_stabilizer_info_played)
	config.set_value("game", "play_character_video_quantum_stabilizer_info", play_character_video_quantum_stabilizer_info)
	config.set_value("game", "has_character_video_dimensional_shift_info_played", has_character_video_dimensional_shift_info_played)
	config.set_value("game", "play_character_video_dimensional_shift_info", play_character_video_dimensional_shift_info)
	config.set_value("game", "has_character_video_entanglement_array_info_played", has_character_video_entanglement_array_info_played)
	config.set_value("game", "play_character_video_entanglement_array_info", play_character_video_entanglement_array_info)

	for upgrade_id in upgrades:
		var upgrade = upgrades[upgrade_id]
		config.set_value("upgrades", upgrade_id + "_initial_cost", upgrade.initial_cost)
		config.set_value("upgrades", upgrade_id + "_cost", upgrade.cost)
		config.set_value("upgrades", upgrade_id + "_level", upgrade.level)
		config.set_value("upgrades", upgrade_id + "_max_level", upgrade.max_level)
	
	var error = config.save("user://savegame.cfg")
	if error != OK:
		print("Error saving game: ", error)

func load_game() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://savegame.cfg")
	if error != OK:
		return  # No save file; use defaults

	player_quanta_generated = config.get_value("game", "player_quanta_generated", 0)
	player_quanta_spent = config.get_value("game", "player_quanta_spent", 0)
	player_quanta_per_second = config.get_value("game", "player_quanta_per_second", 0)
	elapsed_timer = config.get_value("game", "elapsed_timer", 0)
	current_level = config.get_value("game", "current_level", 0)
	cascade_levels = config.get_value("game", "cascade_levels", [])
	is_sound_on = config.get_value("game", "is_sound_on", true)
	is_music_on = config.get_value("game", "is_music_on", true)
	music_last_position = config.get_value("game", "music_last_position", 0.0)
	last_beat_index = config.get_value("game", "last_beat_index", 0)
	last_h_scrollbar_value = config.get_value("game", "last_h_scrollbar_value", 0.0)
	quanta = config.get_value("game", "quanta", 0)
	quanta_per_tap = config.get_value("game", "quanta_per_tap", 1)
	quanta_per_second = config.get_value("game", "quanta_per_second", 0)
	multiplier = config.get_value("game", "multiplier", 1.0)
	cascade_progress = config.get_value("game", "cascade_progress", 0.0)
	cascade_threshold = config.get_value("game", "cascade_threshold", 0.0)
	quanta_accumulator = config.get_value("game", "quanta_accumulator", 0.0)
	has_character_video_pre_cascade_played_this_cascade = config.get_value("game", "has_character_video_pre_cascade_played_this_cascade", true)
	has_character_video_particle_accelerator_info_played = config.get_value("game", "has_character_video_particle_accelerator_info_played", true)
	play_character_video_particle_accelerator_info = config.get_value("game", "play_character_video_particle_accelerator_info", false)
	has_character_video_quantum_stabilizer_info_played = config.get_value("game", "has_character_video_quantum_stabilizer_info_played", true)
	play_character_video_quantum_stabilizer_info = config.get_value("game", "play_character_video_quantum_stabilizer_info", false)
	has_character_video_dimensional_shift_info_played = config.get_value("game", "has_character_video_dimensional_shift_info_played", true)
	play_character_video_dimensional_shift_info = config.get_value("game", "play_character_video_dimensional_shift_info", false)
	has_character_video_entanglement_array_info_played = config.get_value("game", "has_character_video_entanglement_array_info_played", true)
	play_character_video_entanglement_array_info = config.get_value("game", "play_character_video_entanglement_array_info", false)
	
	for upgrade_id in upgrades:
		var upgrade = upgrades[upgrade_id]
		upgrade.cost = config.get_value("upgrades", upgrade_id + "_initial_cost", upgrade.initial_cost)
		upgrade.cost = config.get_value("upgrades", upgrade_id + "_cost", upgrade.cost)
		upgrade.level = config.get_value("upgrades", upgrade_id + "_level", 0)
		upgrade.max_level = config.get_value("upgrades", upgrade_id + "_max_level", 0)
	
	# Recompute effects based on loaded levels
	quanta_per_tap = 1 + upgrades.accelerator.level
	quanta_per_second = 0 + upgrades.stabilizer.level
	multiplier = pow(2, upgrades.shift.level)
	
	last_quanta = quanta
	
	set_progress_bar_max_value(cascade_threshold)
	
	emit_signal("game_state_updated")

func reset_game() -> void:
	# Reset game state to initial values
	player_quanta_generated = 0
	player_quanta_spent = 0
	player_quanta_per_second = 0
	
	set_is_game_paused(false)
	elapsed_timer = 0
	current_level = 0
	has_reached_goal = false

	has_character_video_pre_cascade_played_this_cascade = false

	has_character_video_particle_accelerator_info_played = false
	play_character_video_particle_accelerator_info = false
	has_character_video_quantum_stabilizer_info_played = false
	play_character_video_quantum_stabilizer_info = false
	has_character_video_dimensional_shift_info_played = false
	play_character_video_dimensional_shift_info = false
	has_character_video_entanglement_array_info_played = false
	play_character_video_entanglement_array_info = false

	music_last_position = 0.0
	last_beat_index = 0
	last_h_scrollbar_value = 0.0
	quanta = 0
	quanta_per_tap = 1
	quanta_per_second = 0
	multiplier = 1.0
	cascade_progress = 0.0
	cascade_levels = divide_goal(Globals.QUANTA_GOAL, Globals.QUANTA_LEVELS)
	cascade_threshold = cascade_levels[current_level]
	quanta_accumulator = 0.0
	upgrades = {
		Globals.ACCELERATOR_ID: {"initial_cost": Globals.ACCELERATOR_INITIAL_COST, "cost": Globals.ACCELERATOR_COST, "level": Globals.ACCELERATOR_LEVEL, "max_level": Globals.ACCELERATOR_MAX_LEVEL, "effect": func(): quanta_per_tap += 1},
		Globals.STABILIZER_ID: {"initial_cost": Globals.STABILIZER_INITIAL_COST, "cost": Globals.STABILIZER_COST, "level": Globals.STABILIZER_LEVEL, "max_level": Globals.STABILIZER_MAX_LEVEL, "effect": func(): quanta_per_second += 1},
		Globals.SHIFT_ID: {"initial_cost": Globals.SHIFT_INITIAL_COST, "cost": Globals.SHIFT_COST, "level": Globals.SHIFT_LEVEL, "max_level": Globals.SHIFT_MAX_LEVEL, "effect": func(): multiplier *= 2},
		Globals.ENTANGLEMENT_ID: {"initial_cost": Globals.ENTANGLEMENT_INITIAL_COST, "cost": Globals.ENTANGLEMENT_COST, "level": Globals.ENTANGLEMENT_LEVEL, "max_level": Globals.ENTANGLEMENT_MAX_LEVEL, "effect": func(): pass}
	}

	set_progress_bar_max_value(cascade_threshold)

	last_quanta = quanta
	# Delete save file
	delete_save_file()
	emit_signal("game_state_updated")

func delete_save_file() -> void:
	# Delete save file
	var dir = DirAccess.open("user://")
	if dir.file_exists("savegame.cfg"):
		var error = dir.remove("savegame.cfg")
		if error != OK:
			print("Error deleting save file: ", error)

# A function (or simply in _ready if Gm.gd is initialized after Main scene loads)
func set_progress_bar_max_value(new_max_value: float):
	# Get a reference to the root of the current scene tree
	var root = get_tree().get_root()
	
	# Assuming 'Main' is the root of your main scene and 'CascadeProgress' is a direct child 
	# OR you know the full path (e.g., "Main/CascadeProgress")
	var progress_bar: ProgressBar = root.get_node("Main/ProgressContainer/ProgressDisplay/CascadeProgress")
	
	# A safer way to find the node anywhere in the current scene tree's children:
	# var progress_bar = root.find_node("CascadeProgress", true, false)
	
	if progress_bar and progress_bar is ProgressBar:
		# Change the max_value property
		progress_bar.max_value = new_max_value
		progress_bar.value = cascade_progress

	#print("")
	#print(str(cascade_levels))
	#print(str(current_level))
	#print(str(cascade_levels[current_level]))
	#print(str(cascade_threshold))

func format_number(value: int, delimiter: String) -> String:
	var str_val := str(abs(value))
	var result := ""
	var count := 0

	# Traverse the string backwards and insert delimiters
	for i in range(str_val.length() - 1, -1, -1):
		result = str_val[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = delimiter + result

	# Add the minus sign back if needed
	if value < 0:
		result = "-" + result

	return result

func get_normalized_value(current: float, max_input: float, min_output: float, max_output: float) -> float:
	if max_input == 0.0:
		return min_output  # Avoid division by zero
	var ratio: float = clamp(current / max_input, 0.0, 1.0)
	return lerp(min_output, max_output, ratio)

func _on_quanta_per_second_timer_timeout() -> void:
	if !is_game_paused:
		if !has_reached_goal:
			if quanta_per_second > 0:
				quanta += int(quanta_per_second * multiplier) + get_random_entanglement_quanta()

func _on_elapsed_timer_timeout() -> void:
	if !is_game_paused:
		if !has_reached_goal:
			elapsed_timer += 1

func divide_goal(goal: int, levels: int) -> Array:
	var weights := []
	for i in range(1, levels + 1):
		weights.append(i)
	var total_weight = weights.reduce(func(a, b): return a + b)
	var raw_values = weights.map(func(w): return float(w) / total_weight * goal)
	var result = raw_values.map(func(x): return int(floor(x)))
	var remainder = goal - result.reduce(func(a, b): return a + b)
	for i in range(remainder):
		result[levels - 1 - i] += 1  # add leftover points to the last levels
	return result

func format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	var h = int(seconds / 3600)
	@warning_ignore("integer_division")
	var m = int((seconds % 3600) / 60)
	var s = seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]

func send_request() -> void:
	#HTTPRequest
	pass

func save_high_score():
	var config = ConfigFile.new()
	var file_path = "user://high_scores.cfg"
	
	# Load existing high scores to preserve them
	var error = config.load(file_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		print("Error loading existing high scores: ", error)
		return
	
	# Determine the next section name based on existing sections
	var section = "HighScore" + str(config.get_sections().size() + 1)
	
	# Save current stats as a new entry
	config.set_value(section, "player_quanta_generated", player_quanta_generated)
	config.set_value(section, "player_quanta_spent", player_quanta_spent)
	config.set_value(section, "player_quanta_per_second", player_quanta_per_second)
	config.set_value(section, "elapsed_timer", elapsed_timer)
	
	# Save the updated file (includes existing sections and new entry)
	error = config.save(file_path)
	if error != OK:
		print("Error saving high score: ", error)

func load_high_scores() -> Array:
	var config = ConfigFile.new()
	var file_path = "user://high_scores.cfg"
	var high_scores = []
	
	# Load the file if it exists
	var error = config.load(file_path)
	if error != OK:
		if error == ERR_FILE_NOT_FOUND:
			return [] # Return empty array if file doesn't exist
		print("Error loading high scores: ", error)
		return []
	
	# Iterate through sections to collect all high score entries
	for section in config.get_sections():
		var score_entry = {
			"player_quanta_generated": config.get_value(section, "player_quanta_generated", 0),
			"player_quanta_spent": config.get_value(section, "player_quanta_spent", 0),
			"player_quanta_per_second": config.get_value(section, "player_quanta_per_second", 0),
			"elapsed_timer": config.get_value(section, "elapsed_timer", 0)
		}
		high_scores.append(score_entry)
	
	return high_scores

func set_is_game_paused(value: bool):
	is_game_paused = value
	emit_signal("pause_state_changed")
