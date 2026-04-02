extends Node

## 텍스처/이미지 에셋 로딩 관리 오토로드.
## 에셋 경로 표준화, 캐싱, placeholder 자동 생성을 담당한다.
## 실제 이미지 파일이 없으면 카테고리별 컬러 placeholder를 반환한다.

# --- 에셋 경로 규칙 ---
# res://art/cards/{card_id}.png        카드 일러스트
# res://art/enemies/{enemy_id}.png     적 스프라이트
# res://art/backgrounds/{scene_key}.png  배경 이미지
# res://art/ui/icons/{icon_name}.png   UI 아이콘
# res://art/effects/{effect_name}.png  이펙트 스프라이트

enum AssetCategory {
	CARD,
	ENEMY,
	BACKGROUND,
	UI_ICON,
	EFFECT,
}

## 카테고리별 기본 디렉토리
const CATEGORY_PATHS := {
	AssetCategory.CARD: "res://art/cards/",
	AssetCategory.ENEMY: "res://art/enemies/",
	AssetCategory.BACKGROUND: "res://art/backgrounds/",
	AssetCategory.UI_ICON: "res://art/ui/icons/",
	AssetCategory.EFFECT: "res://art/effects/",
}

## 카테고리별 placeholder 색상 (배경색, 전경 텍스트 색)
const PLACEHOLDER_COLORS := {
	AssetCategory.CARD: Color(0.25, 0.2, 0.35),
	AssetCategory.ENEMY: Color(0.5, 0.15, 0.15),
	AssetCategory.BACKGROUND: Color(0.08, 0.06, 0.14),
	AssetCategory.UI_ICON: Color(0.3, 0.3, 0.4),
	AssetCategory.EFFECT: Color(0.15, 0.3, 0.35),
}

## 카드 타입별 placeholder 색상
const CARD_TYPE_COLORS := {
	"attack": Color(0.6, 0.15, 0.12),
	"defense": Color(0.12, 0.35, 0.6),
	"spell": Color(0.4, 0.18, 0.6),
	"movement": Color(0.12, 0.5, 0.3),
	"formation": Color(0.6, 0.45, 0.1),
}

## 캐시 (path → Texture2D)
var _texture_cache: Dictionary = {}
## placeholder 캐시 (cache_key → ImageTexture)
var _placeholder_cache: Dictionary = {}

## placeholder 기본 크기
const PLACEHOLDER_SIZE := Vector2i(256, 256)
const CARD_PLACEHOLDER_SIZE := Vector2i(256, 384)
const BG_PLACEHOLDER_SIZE := Vector2i(1080, 1920)


# --- 공개 API ---

func get_card_texture(card_id: String, card_type: String = "") -> Texture2D:
	## 카드 일러스트 텍스처를 반환한다.
	## 실제 파일이 없으면 타입별 컬러 placeholder를 생성한다.
	var path := CATEGORY_PATHS[AssetCategory.CARD] + card_id + ".png"
	var tex := _load_texture(path)
	if tex:
		return tex
	return _get_card_placeholder(card_id, card_type)


func get_enemy_texture(enemy_id: String) -> Texture2D:
	## 적 스프라이트 텍스처를 반환한다.
	var path := CATEGORY_PATHS[AssetCategory.ENEMY] + enemy_id + ".png"
	var tex := _load_texture(path)
	if tex:
		return tex
	return _get_placeholder(AssetCategory.ENEMY, enemy_id, PLACEHOLDER_SIZE)


func get_background_texture(scene_key: String) -> Texture2D:
	## 배경 이미지 텍스처를 반환한다.
	var path := CATEGORY_PATHS[AssetCategory.BACKGROUND] + scene_key + ".png"
	var tex := _load_texture(path)
	if tex:
		return tex
	return _get_placeholder(AssetCategory.BACKGROUND, scene_key, BG_PLACEHOLDER_SIZE)


func get_ui_icon(icon_name: String) -> Texture2D:
	## UI 아이콘 텍스처를 반환한다.
	var path := CATEGORY_PATHS[AssetCategory.UI_ICON] + icon_name + ".png"
	var tex := _load_texture(path)
	if tex:
		return tex
	return _get_placeholder(AssetCategory.UI_ICON, icon_name, Vector2i(64, 64))


func get_effect_texture(effect_name: String) -> Texture2D:
	## 이펙트 스프라이트 텍스처를 반환한다.
	var path := CATEGORY_PATHS[AssetCategory.EFFECT] + effect_name + ".png"
	var tex := _load_texture(path)
	if tex:
		return tex
	return _get_placeholder(AssetCategory.EFFECT, effect_name, Vector2i(128, 128))


func has_real_texture(category: AssetCategory, asset_id: String) -> bool:
	## 실제 에셋 파일이 존재하는지 확인한다 (placeholder 아님).
	var path := CATEGORY_PATHS[category] + asset_id + ".png"
	return ResourceLoader.exists(path)


func clear_cache() -> void:
	## 전체 캐시를 초기화한다.
	_texture_cache.clear()
	_placeholder_cache.clear()


# --- 내부 구현 ---

func _load_texture(path: String) -> Texture2D:
	## 텍스처를 캐시에서 로드하거나 리소스에서 불러온다.
	if _texture_cache.has(path):
		return _texture_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var tex = load(path)
	if tex is Texture2D:
		_texture_cache[path] = tex
		return tex
	return null


func _get_card_placeholder(card_id: String, card_type: String) -> ImageTexture:
	## 카드 타입별 컬러 placeholder를 생성/캐시한다.
	var cache_key := "card_%s_%s" % [card_type, card_id]
	if _placeholder_cache.has(cache_key):
		return _placeholder_cache[cache_key]

	var bg_color: Color = CARD_TYPE_COLORS.get(card_type, PLACEHOLDER_COLORS[AssetCategory.CARD])
	var tex := _create_placeholder_texture(CARD_PLACEHOLDER_SIZE, bg_color, card_id)
	_placeholder_cache[cache_key] = tex
	return tex


func _get_placeholder(category: AssetCategory, asset_id: String, size: Vector2i) -> ImageTexture:
	## 카테고리별 기본 placeholder를 생성/캐시한다.
	var cache_key := "%d_%s" % [category, asset_id]
	if _placeholder_cache.has(cache_key):
		return _placeholder_cache[cache_key]

	var bg_color: Color = PLACEHOLDER_COLORS[category]
	var tex := _create_placeholder_texture(size, bg_color, asset_id)
	_placeholder_cache[cache_key] = tex
	return tex


func _create_placeholder_texture(size: Vector2i, bg_color: Color, label_text: String) -> ImageTexture:
	## 단색 배경 + 중앙 라벨이 있는 placeholder 이미지를 생성한다.
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)

	# 배경 채우기
	img.fill(bg_color)

	# 테두리 그리기 (2px)
	var border_color := bg_color.lightened(0.3)
	for x in size.x:
		for y in [0, 1, size.y - 2, size.y - 1]:
			img.set_pixel(x, y, border_color)
	for y in size.y:
		for x in [0, 1, size.x - 2, size.x - 1]:
			img.set_pixel(x, y, border_color)

	# 중앙에 십자 패턴 (에셋 위치 표시)
	var cx := size.x / 2
	var cy := size.y / 2
	var cross_color := bg_color.lightened(0.15)
	for i in range(-20, 21):
		if cx + i >= 0 and cx + i < size.x:
			img.set_pixel(cx + i, cy, cross_color)
		if cy + i >= 0 and cy + i < size.y:
			img.set_pixel(cx, cy + i, cross_color)

	return ImageTexture.create_from_image(img)
