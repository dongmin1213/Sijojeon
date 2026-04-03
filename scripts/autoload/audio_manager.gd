extends Node

## 오디오 재생 관리 오토로드.
## BGM/SFX 재생, 씬별 BGM 전환, 볼륨 조절을 담당한다.

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

## 볼륨 (0.0 ~ 1.0 linear)
var bgm_volume: float = 0.8:
	set(value):
		bgm_volume = clampf(value, 0.0, 1.0)
		if _bgm_player:
			_bgm_player.volume_db = linear_to_db(bgm_volume)

var sfx_volume: float = 0.8:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)

## 씬별 BGM 경로 (5음 음계 기반 플레이스홀더 WAV — 추후 전문 에셋으로 교체)
const BGM_PATHS := {
	"title": "res://art/audio/bgm/title.wav",
	"map": "res://art/audio/bgm/map.wav",
	"battle": "res://art/audio/bgm/battle.wav",
	"shop": "res://art/audio/bgm/shop.wav",
	"rest": "res://art/audio/bgm/rest.wav",
	"boss": "res://art/audio/bgm/boss.wav",
}

## SFX 경로
const SFX_PATHS := {
	"card_play": "res://art/audio/sfx/card_play.wav",
	"card_draw": "res://art/audio/sfx/card_draw.wav",
	"damage": "res://art/audio/sfx/damage.wav",
	"heal": "res://art/audio/sfx/heal.wav",
	"block": "res://art/audio/sfx/block.wav",
	"victory": "res://art/audio/sfx/victory.wav",
	"defeat": "res://art/audio/sfx/defeat.wav",
	"button_click": "res://art/audio/sfx/button_click.wav",
	"coin": "res://art/audio/sfx/coin.wav",
	"buff": "res://art/audio/sfx/buff.wav",
	"debuff": "res://art/audio/sfx/debuff.wav",
	"enemy_attack": "res://art/audio/sfx/enemy_attack.wav",
	"sijo_slot": "res://art/audio/sfx/sijo_slot.wav",
	"sijo_complete": "res://art/audio/sfx/sijo_complete.wav",
	"end_turn": "res://art/audio/sfx/end_turn.wav",
	"upgrade": "res://art/audio/sfx/upgrade.wav",
}

## 캐시된 스트림
var _stream_cache: Dictionary = {}
var _current_bgm_key: String = ""


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Music"
	add_child(_bgm_player)

	for i in MAX_SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	# 저장된 볼륨 설정 로드
	var settings := SaveManager.load_settings()
	bgm_volume = settings.get("bgm_volume", 0.8)
	sfx_volume = settings.get("sfx_volume", 0.8)

	# GameManager 상태 변경 시 BGM 자동 전환
	GameManager.state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.TITLE:
			play_bgm_by_key("title")
		GameManager.GameState.MAP:
			play_bgm_by_key("map")
		GameManager.GameState.BATTLE:
			# 보스전 구분
			var is_boss := false
			if GameManager.run_data:
				is_boss = GameManager.run_data.current_node_type == MapData.NodeType.BOSS
			play_bgm_by_key("boss" if is_boss else "battle")
		GameManager.GameState.SHOP:
			play_bgm_by_key("shop")
		GameManager.GameState.REST:
			play_bgm_by_key("rest")
		GameManager.GameState.RUN_OVER:
			stop_bgm_fade()
		GameManager.GameState.RUN_WIN:
			stop_bgm_fade()


func play_bgm_by_key(key: String) -> void:
	## BGM 키로 재생. 같은 키면 무시, 파일 없으면 무시.
	if key == _current_bgm_key and _bgm_player.playing:
		return
	var path: String = BGM_PATHS.get(key, "")
	if path == "":
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	_current_bgm_key = key
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume)
	_bgm_player.play()


func play_bgm(stream: AudioStream) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume)
	_bgm_player.play()
	_current_bgm_key = ""


func stop_bgm() -> void:
	_bgm_player.stop()
	_current_bgm_key = ""


func stop_bgm_fade(duration: float = 0.5) -> void:
	## BGM 페이드 아웃 후 정지
	var tween := create_tween()
	tween.tween_property(_bgm_player, "volume_db", -40.0, duration)
	tween.tween_callback(stop_bgm)


func play_sfx(stream: AudioStream) -> void:
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(sfx_volume)
			p.play()
			return


func play_sfx_by_key(key: String) -> void:
	## SFX 키로 재생. 파일 없으면 무시.
	var path: String = SFX_PATHS.get(key, "")
	if path == "":
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	play_sfx(stream)


func _load_stream(path: String) -> AudioStream:
	## 스트림을 캐시에서 로드하거나 리소스에서 불러온다.
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	if stream is AudioStream:
		_stream_cache[path] = stream
		return stream
	return null
