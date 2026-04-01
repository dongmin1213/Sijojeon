extends Node

## 오디오 재생 관리 오토로드.

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

var bgm_volume: float = 1.0
var sfx_volume: float = 1.0


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Music"
	add_child(_bgm_player)

	for i in MAX_SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)


func play_bgm(stream: AudioStream) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume)
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()


func play_sfx(stream: AudioStream) -> void:
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(sfx_volume)
			p.play()
			return
