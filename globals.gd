class_name Globals

const UI_FONT_SIZE_SMALLER: int = 12
const UI_FONT_SIZE_SMALL: int = 14
const UI_FONT_SIZE_NORMAL: int = 20
const UI_FONT_SIZE_LARGE: int = 24

const UPGRADE_NAME_FONT_SIZE: int = 12
const UPGRADE_INFO_FONT_SIZE: int = 10

const FONT_KENNEY_FUTURE := preload("res://Assets/Fonts/Kenney Future.ttf")

const UI_FONT_LIGHT := preload("res://Assets/Fonts/ClearSans-Light.ttf")
const UI_FONT_REGULAR := preload("res://Assets/Fonts/ClearSans-Regular.ttf")
const UI_FONT_BOLD := preload("res://Assets/Fonts/ClearSans-Bold.ttf")

const QUANTA_LABEL_FONT := FONT_KENNEY_FUTURE
const CASCADE_PROGRESS_FONT := FONT_KENNEY_FUTURE

#region ALIX DIALOGUES
## We are close to a breakthrough. Accelerate production to trigger the cascade!
const ALIX_PRE_CASCADE := preload("res://Assets/Videos/Characters/Alix/pre-cascade.ogv")

## The Particle Accelerator will provide us with extra Quanta per action.
const ALIX_PARTICLE_ACCELERATOR_INFO := preload("res://Assets/Videos/Characters/Alix/particle-acccelerator-info.ogv")

## We must rely on the Quantum Stabilizer for passive Quanta generation.
const ALIX_QUANTUM_STABILIZER_INFO := preload("res://Assets/Videos/Characters/Alix/quantum-stabilizer-info.ogv")

## Dimensional shift detected. It will double our efforts.
const ALIX_DIMENSIONAL_SHIFT_INFO := preload("res://Assets/Videos/Characters/Alix/dimensional-shift-info.ogv")

#endregion

const CORNER_RADIUS: int = 16
const HORIZONTAL_CORNER_RADIUS: int = 8
const VERTICAL_CORNER_RADIUS: int = 8

const MIN_CASCADE_THRESHOLD: float = 100.0
const MAX_CASCADE_THRESHOLD: float = 100000.0
const CASCADE_THRESHOLD_MULTIPLIER: int = 2

const QUANTA_LABEL_TEXT: String = "QUANTA"

const QUANTUM_CORE_TWEEN_DURATION: float = 0.15
const QUANTUM_CORE_TWEEN_DELAY: float = 0.1
const QUANTUM_CORE_ORIGINAL_SCALE: Vector2 = Vector2(0.75, 0.75)
const QUANTUM_CORE_MAX_SCALE: Vector2 = Vector2(1.2, 1.2)

const UPGRADE_TWEEN_DURATION: float = 0.15
const UPGRADE_TWEEN_DELAY: float = 0.15

const UPGRADE_MULTIPLIER: float = 1.5
const UPGRADE_INCREMENT: float = 50.0
const UPGRADE_BASE_LOG: float = 10.0

const UPGRADE_PROGRESSION: UPGRADE_PROGRESSION_FORMULA = UPGRADE_PROGRESSION_FORMULA.LOGARITHMIC

enum UPGRADE_PROGRESSION_FORMULA {
	LINEAR,
	QUADRATIC,
	EXPONENTIAL,
	EXPONENTIAL_VAR_BASE,
	FIBONACCI_LIKE,
	LOGARITHMIC
}

const ACCELERATOR_ID: String = "accelerator"
const ACCELERATOR_INITIAL_COST: int = 50
const ACCELERATOR_COST: int = 50
const ACCELERATOR_LEVEL: int = 0
const ACCELERATOR_MAX_LEVEL: int = 25

const STABILIZER_ID: String = "stabilizer"
const STABILIZER_INITIAL_COST: int = 200
const STABILIZER_COST: int = 200
const STABILIZER_LEVEL: int = 0
const STABILIZER_MAX_LEVEL: int = 15

const SHIFT_ID: String = "shift"
const SHIFT_INITIAL_COST: int = 500
const SHIFT_COST: int = 500
const SHIFT_LEVEL: int = 0
const SHIFT_MAX_LEVEL: int = 6

#const QUANTA_GOAL: int = 9223372036854775807
#const QUANTA_GOAL: int = 1000
const QUANTA_GOAL: int = 775807

const CIRCULAR_CASCADE_PROGRESS_ROTATION_SPEED: float = 0.05 # radians per second
const CIRCULAR_CASCADE_PROGRESS_MINIMUM_RING_THICKNESS: float = 0.01
const CIRCULAR_CASCADE_PROGRESS_MAXIMUM_RING_THICKNESS: float = 0.07
