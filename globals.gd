class_name Globals

const UI_FONT_SIZE_SMALL: int = 14
const UI_FONT_SIZE_NORMAL: int = 20
const UI_FONT_SIZE_LARGE: int = 24

const UPGRADE_NAME_FONT_SIZE: int = 12
const UPGRADE_INFO_FONT_SIZE: int = 10

const UI_FONT_LIGHT := preload("res://Assets/Fonts/ClearSans-Light.ttf")
const UI_FONT_REGULAR := preload("res://Assets/Fonts/ClearSans-Regular.ttf")
const UI_FONT_BOLD := preload("res://Assets/Fonts/ClearSans-Bold.ttf")

const CORNER_RADIUS: int = 16
const HORIZONTAL_CORNER_RADIUS: int = 8
const VERTICAL_CORNER_RADIUS: int = 8

const MAX_CASCADE_THRESHOLD: float = 100000.0

const QUANTA_LABEL_TEXT: String = "QUANTA"

const QUANTUM_CORE_TWEEN_DURATION: float = 0.15
const QUANTUM_CORE_TWEEN_DELAY: float = 0.1
const QUANTUM_CORE_ORIGINAL_SCALE: Vector2 = Vector2(0.88, 0.88)

const UPGRADE_TWEEN_DURATION: float = 0.15
const UPGRADE_TWEEN_DELAY: float = 0.15

const UPGRADE_MULTIPLIER: float = 1.5
const UPGRADE_INCREMENT: float = 50.0
const UPGRADE_BASE_LOG: float = 10.0

const UPGRADE_PROGRESSION: UPGRADE_PROGRESSION_FORMULA = UPGRADE_PROGRESSION_FORMULA.QUADRATIC

enum UPGRADE_PROGRESSION_FORMULA {
	LINEAR,
	QUADRATIC,
	EXPONENTIAL,
	EXPONENTIAL_VAR_BASE,
	FIBONACCI_LIKE,
	LOGARITHMIC
}
