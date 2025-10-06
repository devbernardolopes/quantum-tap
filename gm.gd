extends Node

var _quanta_internal: int = 0

## 9223372036854775807 Biggest value an int can store
var quanta: int:
	get:
		return _quanta_internal
	set(value):
		if _quanta_internal == value:
			return
		_quanta_internal = value
		emit_signal("quanta_changed", value)

var quanta_per_tap: int = 1
var quanta_per_second: int = 0
var multiplier: float = 1.0
var quanta_accumulator: float = 0.0
var cascade_progress: float = 0.0
var cascade_threshold: float = Globals.MIN_CASCADE_THRESHOLD

var upgrades: Dictionary = {
	"accelerator": {"initial_cost": Globals.ACCELERATOR_INITIAL_COST, "cost": Globals.ACCELERATOR_COST, "level": Globals.ACCELERATOR_LEVEL, "max_level": Globals.ACCELERATOR_MAX_LEVEL, "effect": func(): quanta_per_tap += 1},
	"stabilizer": {"initial_cost": Globals.STABILIZER_INITIAL_COST, "cost": Globals.STABILIZER_COST, "level": Globals.STABILIZER_LEVEL, "max_level": Globals.STABILIZER_MAX_LEVEL, "effect": func(): quanta_per_second += 1},
	"shift": {"initial_cost": Globals.SHIFT_INITIAL_COST, "cost": Globals.SHIFT_COST, "level": Globals.SHIFT_LEVEL, "max_level": Globals.SHIFT_MAX_LEVEL, "effect": func(): multiplier *= 2}
}

signal game_state_updated
signal quanta_changed(new_value: int)

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	if quanta_per_second > 0:
		# Accumulate fractional Quanta
		quanta_accumulator += quanta_per_second * delta * multiplier
		# Add whole Quanta when accumulator reaches 1 or more
		if quanta_accumulator >= 1.0:
			var whole_quanta = int(quanta_accumulator)
			quanta += whole_quanta
			quanta_accumulator -= whole_quanta

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		
func add_quanta(amount: int) -> void:
	quanta += int(amount * multiplier)
	#quanta += int(amount)
	cascade_progress += amount
	if cascade_progress >= cascade_threshold:
		trigger_cascade()

func get_upgrade_cost(initial_cost: int, cost: int, level: int, formula: Globals.UPGRADE_PROGRESSION_FORMULA = Globals.UPGRADE_PROGRESSION_FORMULA.EXPONENTIAL) -> int:
	var result: int = 0
	
	match formula:
		Globals.UPGRADE_PROGRESSION_FORMULA.QUADRATIC:
			return int(cost + Globals.UPGRADE_INCREMENT * pow((level + 1), 2))

		Globals.UPGRADE_PROGRESSION_FORMULA.EXPONENTIAL:
			return int(cost * Globals.UPGRADE_MULTIPLIER)

		Globals.UPGRADE_PROGRESSION_FORMULA.EXPONENTIAL_VAR_BASE:
			return int(cost * (1.2 + (0.1 * level)))

		Globals.UPGRADE_PROGRESSION_FORMULA.LOGARITHMIC:
			return int(initial_cost * log(Globals.UPGRADE_BASE_LOG + level))

		Globals.UPGRADE_PROGRESSION_FORMULA.FIBONACCI_LIKE:
			pass

	return result

func purchase_upgrade(upgrade_id: String) -> bool:
	var upgrade = upgrades[upgrade_id]
	if quanta >= upgrade.cost:
		quanta -= upgrade.cost
		#upgrade.level += 1
		upgrade.level = min(upgrade.level + 1, upgrade.max_level)
		upgrade.cost = get_upgrade_cost(upgrade.initial_cost, upgrade.cost, upgrade.level, Globals.UPGRADE_PROGRESSION)
		#upgrade.cost = int(upgrade.cost + Globals.UPGRADE_INCREMENT * pow(upgrade.level, 2))
		#upgrade.cost = int(upgrade.cost * Globals.UPGRADE_COST_MULTIPLIER) # Cost increases by 50% per level
		upgrade.effect.call()
		return true
	return false

func trigger_cascade() -> void:
	var bonus = quanta * (1.0 + upgrades.accelerator.level * 0.1)
	quanta += int(bonus)
	cascade_progress = 0.0
	cascade_threshold *= Globals.CASCADE_THRESHOLD_MULTIPLIER
	cascade_threshold = min(cascade_threshold, Globals.MAX_CASCADE_THRESHOLD)
	set_progress_bar_max_value(cascade_threshold)

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("game", "quanta", quanta)
	config.set_value("game", "quanta_per_tap", quanta_per_tap)
	config.set_value("game", "quanta_per_second", quanta_per_second)
	config.set_value("game", "multiplier", multiplier)
	config.set_value("game", "cascade_progress", cascade_progress)
	config.set_value("game", "cascade_threshold", cascade_threshold)
	config.set_value("game", "quanta_accumulator", quanta_accumulator)
	
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
	
	quanta = config.get_value("game", "quanta", 0)
	quanta_per_tap = config.get_value("game", "quanta_per_tap", 1)
	quanta_per_second = config.get_value("game", "quanta_per_second", 0)
	multiplier = config.get_value("game", "multiplier", 1.0)
	cascade_progress = config.get_value("game", "cascade_progress", 0.0)
	cascade_threshold = config.get_value("game", "cascade_threshold", 0.0)
	quanta_accumulator = config.get_value("game", "quanta_accumulator", 0.0)
	
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
	
	set_progress_bar_max_value(cascade_threshold)
	
	emit_signal("game_state_updated")

func reset_game() -> void:
	# Reset game state to initial values
	quanta = 0
	quanta_per_tap = 1
	quanta_per_second = 0
	multiplier = 1.0
	cascade_progress = 0.0
	cascade_threshold = Globals.MIN_CASCADE_THRESHOLD
	quanta_accumulator = 0.0
	upgrades = {
		"accelerator": {"initial_cost": Globals.ACCELERATOR_INITIAL_COST, "cost": Globals.ACCELERATOR_COST, "level": Globals.ACCELERATOR_LEVEL, "max_level": Globals.ACCELERATOR_MAX_LEVEL, "effect": func(): quanta_per_tap += 1},
		"stabilizer": {"initial_cost": Globals.STABILIZER_INITIAL_COST, "cost": Globals.STABILIZER_COST, "level": Globals.STABILIZER_LEVEL, "max_level": Globals.STABILIZER_MAX_LEVEL, "effect": func(): quanta_per_second += 1},
		"shift": {"initial_cost": Globals.SHIFT_INITIAL_COST, "cost": Globals.SHIFT_COST, "level": Globals.SHIFT_LEVEL, "max_level": Globals.SHIFT_MAX_LEVEL, "effect": func(): multiplier *= 2}
	}
	set_progress_bar_max_value(cascade_threshold)
	
	# Delete save file
	var dir = DirAccess.open("user://")
	if dir.file_exists("savegame.cfg"):
		var error = dir.remove("savegame.cfg")
		if error != OK:
			print("Error deleting save file: ", error)
	emit_signal("game_state_updated")

# A function (or simply in _ready if Gm.gd is initialized after Main scene loads)
func set_progress_bar_max_value(new_max_value: float):
	# Get a reference to the root of the current scene tree
	var root = get_tree().get_root()
	
	# Assuming 'Main' is the root of your main scene and 'CascadeProgress' is a direct child 
	# OR you know the full path (e.g., "Main/CascadeProgress")
	var progress_bar = root.get_node("Main/ProgressContainer/ProgressDisplay/CascadeProgress")
	
	# A safer way to find the node anywhere in the current scene tree's children:
	# var progress_bar = root.find_node("CascadeProgress", true, false)
	
	if progress_bar and progress_bar is ProgressBar:
		# Change the max_value property
		progress_bar.max_value = new_max_value
		print("Updated CascadeProgress max_value to: ", new_max_value)
	else:
		# This will help debug if the node is not found or is the wrong type
		print("Error: Could not find ProgressBar node named 'CascadeProgress'.")

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
