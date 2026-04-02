extends Control

## 타이틀 화면. 게임 시작, 이어하기, 연대기, 설정 등 메인 메뉴 제공.

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var daily_button: Button = $VBoxContainer/DailyChallengeButton
@onready var chronicle_button: Button = $VBoxContainer/ChronicleButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	# 이어하기 버튼: 세이브 있을 때만 표시
	continue_button.visible = SaveManager.has_run_save()

	# 일일 도전: 오늘 이미 완료했으면 비활성화
	if GameManager.has_daily_challenge_today():
		daily_button.text = "일일 도전 (완료)"
		daily_button.disabled = true

	# 버전 표시
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0")

	# 버튼 연결
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	daily_button.pressed.connect(_on_daily_pressed)
	chronicle_button.pressed.connect(_on_chronicle_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 타이틀 페이드인 연출
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)


func _on_start_pressed() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)


func _on_continue_pressed() -> void:
	GameManager.load_saved_run()


func _on_daily_pressed() -> void:
	# 일일 도전은 랜덤 캐릭터 사용 (날짜 시드 기반)
	var today := Time.get_date_string_from_system()
	var chars := ["mugwan", "dosa", "mungwan"]
	var char_index := today.hash() % chars.size()
	GameManager.start_daily_challenge(chars[char_index])


func _on_chronicle_pressed() -> void:
	GameManager.change_state(GameManager.GameState.CHRONICLE)


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)


func _on_quit_pressed() -> void:
	get_tree().quit()
