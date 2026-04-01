extends Control

## 설정 화면. 사운드 볼륨, 진동 on/off를 조절하고 SaveManager에 저장한다.

@onready var bgm_slider: HSlider = $VBoxContainer/BGMContainer/BGMSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXContainer/SFXSlider
@onready var vibration_check: CheckButton = $VBoxContainer/VibrationContainer/VibrationCheck
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	# 저장된 설정 로드
	var settings := SaveManager.load_settings()
	bgm_slider.value = settings.get("bgm_volume", 0.8)
	sfx_slider.value = settings.get("sfx_volume", 0.8)
	vibration_check.button_pressed = settings.get("vibration", true)

	# 시그널 연결
	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	vibration_check.toggled.connect(_on_vibration_toggled)
	back_button.pressed.connect(_on_back_pressed)

	# 즉시 적용
	AudioManager.bgm_volume = bgm_slider.value
	AudioManager.sfx_volume = sfx_slider.value


func _on_bgm_changed(value: float) -> void:
	AudioManager.bgm_volume = value
	_save()


func _on_sfx_changed(value: float) -> void:
	AudioManager.sfx_volume = value
	_save()


func _on_vibration_toggled(_pressed: bool) -> void:
	_save()


func _save() -> void:
	SaveManager.save_settings({
		"bgm_volume": bgm_slider.value,
		"sfx_volume": sfx_slider.value,
		"vibration": vibration_check.button_pressed,
	})


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.TITLE)
