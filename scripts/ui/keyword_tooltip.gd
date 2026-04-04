class_name KeywordTooltip
extends CanvasLayer

## 키워드 툴팁 컴포넌트.
## 상태효과, 메카닉 키워드를 호버(PC) 또는 길게 누르기(모바일) 시 설명 팝업을 표시한다.
## 싱글 인스턴스로 사용 — 전투 씬에 하나만 추가하고 show_tooltip()으로 호출.

var _panel: PanelContainer = null
var _name_label: Label = null
var _desc_label: Label = null
var _visible := false

# 키워드 사전 캐시
static var _keyword_cache: Dictionary = {}
static var _cache_loaded: bool = false


func _ready() -> void:
	layer = 95
	_build_ui()
	_load_keywords()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(0.7, 0.6, 0.4, 0.9)
	stylebox.set_corner_radius_all(6)
	stylebox.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", stylebox)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_size_override("font_size", 15)
	_desc_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
	_desc_label.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(_desc_label)

	_panel.add_child(vbox)
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)


func _load_keywords() -> void:
	if _cache_loaded:
		return

	var path := "res://data/keywords.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("KeywordTooltip: keywords.json 로드 실패")
		_cache_loaded = true
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK or not (json.data is Dictionary):
		push_warning("KeywordTooltip: keywords.json 파싱 실패")
		_cache_loaded = true
		return

	var keywords: Array = json.data.get("keywords", [])
	for kw in keywords:
		if kw is Dictionary and kw.has("id"):
			_keyword_cache[kw["id"]] = kw
			# 한글 이름으로도 조회 가능하게
			var name_str: String = kw.get("name", "")
			if name_str != "" and name_str != kw["id"]:
				_keyword_cache[name_str] = kw

	_cache_loaded = true


## 특정 키워드의 툴팁을 지정 위치에 표시한다.
func show_tooltip(keyword_id: String, global_pos: Vector2) -> void:
	var kw: Dictionary = _keyword_cache.get(keyword_id, {})
	if kw.is_empty():
		# StatusEffectData에서 fallback 시도
		var def := StatusEffectData.get_definition(keyword_id)
		if def:
			_name_label.text = def.name_ko
			_desc_label.text = def.description
			_name_label.add_theme_color_override("font_color", def.color)
		else:
			return
	else:
		_name_label.text = _get_localized(kw, "name", keyword_id)
		_desc_label.text = _get_localized(kw, "description", "")
		var color_hex: String = kw.get("color", "#FFD966")
		_name_label.add_theme_color_override("font_color", Color.from_string(color_hex, Color(1, 0.85, 0.3)))

	_panel.visible = true
	_visible = true

	# 패널 크기 계산 후 화면 내에 위치 조정
	await get_tree().process_frame
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := _panel.size
	var pos := global_pos

	# 화면 오른쪽 밖으로 나가지 않도록
	if pos.x + panel_size.x > viewport_size.x - 10:
		pos.x = viewport_size.x - panel_size.x - 10
	# 화면 아래쪽 밖으로 나가지 않도록
	if pos.y + panel_size.y > viewport_size.y - 10:
		pos.y = pos.y - panel_size.y - 10
	# 화면 왼쪽/위쪽 클램핑
	pos.x = maxf(pos.x, 10)
	pos.y = maxf(pos.y, 10)

	_panel.position = pos


## 툴팁 숨기기
func hide_tooltip() -> void:
	_panel.visible = false
	_visible = false


## 다국어 딕셔너리에서 현재 로케일에 맞는 텍스트 반환.
func _get_localized(kw: Dictionary, field: String, fallback: String) -> String:
	var value = kw.get(field, fallback)
	if value is Dictionary:
		var locale := TranslationServer.get_locale()
		if value.has(locale) and str(value[locale]) != "":
			return str(value[locale])
		if value.has("ko"):
			return str(value["ko"])
		return fallback
	return str(value) if value else fallback


## 키워드 ID로 데이터가 있는지 확인
static func has_keyword(keyword_id: String) -> bool:
	if not _cache_loaded:
		return false
	if _keyword_cache.has(keyword_id):
		return true
	# StatusEffectData fallback
	return StatusEffectData.get_definition(keyword_id) != null


## 전체 키워드 목록 반환
static func get_all_keywords() -> Dictionary:
	return _keyword_cache


func _input(event: InputEvent) -> void:
	# 아무 곳이나 터치/클릭하면 툴팁 숨기기
	if _visible and event is InputEventMouseButton and event.pressed:
		hide_tooltip()
