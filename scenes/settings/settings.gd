extends Control

## 설정 화면. 사운드, 접근성 옵션을 조절하고 SaveManager에 저장한다.

@onready var bgm_slider: HSlider = $VBoxContainer/BGMContainer/BGMSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXContainer/SFXSlider
@onready var vibration_check: CheckButton = $VBoxContainer/VibrationContainer/VibrationCheck
@onready var screen_shake_check: CheckButton = $VBoxContainer/ScreenShakeContainer/ScreenShakeCheck
@onready var language_option: OptionButton = $VBoxContainer/LanguageContainer/LanguageOption
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	# 언어 옵션 추가
	for locale in TranslationManager.SUPPORTED_LOCALES:
		language_option.add_item(TranslationManager.get_locale_display_name(locale))
	language_option.selected = TranslationManager.get_locale_index()

	# 저장된 설정 로드
	var settings := SaveManager.load_settings()
	bgm_slider.value = settings.get("bgm_volume", 0.8)
	sfx_slider.value = settings.get("sfx_volume", 0.8)
	vibration_check.button_pressed = settings.get("vibration", true)
	screen_shake_check.button_pressed = settings.get("screen_shake_enabled", true)

	# 시그널 연결
	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	vibration_check.toggled.connect(_on_vibration_toggled)
	screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	language_option.item_selected.connect(_on_language_changed)
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


func _on_vibration_toggled(pressed: bool) -> void:
	if pressed:
		# 진동 ON 시 짧은 피드백으로 확인
		Input.vibrate_handheld(100)
	_save()


func _on_screen_shake_toggled(pressed: bool) -> void:
	AccessibilityManager.set_screen_shake_enabled(pressed)
	_save()


func _on_language_changed(index: int) -> void:
	var locale: String = TranslationManager.SUPPORTED_LOCALES[index]
	TranslationManager.set_locale(locale)


func _save() -> void:
	SaveManager.save_settings({
		"bgm_volume": bgm_slider.value,
		"sfx_volume": sfx_slider.value,
		"vibration": vibration_check.button_pressed,
		"screen_shake_enabled": screen_shake_check.button_pressed,
		"locale": TranslationManager.get_locale(),
	})


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.TITLE)
