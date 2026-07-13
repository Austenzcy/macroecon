extends Node

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _audio_unlocked := false
var _bgm_stream: AudioStreamWAV
var _card_sfx_stream: AudioStreamWAV


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	add_child(_sfx_player)

	_bgm_stream = _make_tone_stream(220.0, 1.5, 0.14, true)
	_card_sfx_stream = _make_tone_stream(720.0, 0.12, 0.35, false)


func unlock_audio_from_user_gesture() -> void:
	_audio_unlocked = true


func play_bgm() -> void:
	if not _audio_unlocked:
		return
	if _bgm_player.stream == null:
		_bgm_player.stream = _bgm_stream
	if not _bgm_player.playing:
		_bgm_player.play()


func play_sfx(name: StringName = &"card_play") -> void:
	if not _audio_unlocked:
		return
	match name:
		&"card_play":
			_sfx_player.stream = _card_sfx_stream
		_:
			_sfx_player.stream = _card_sfx_stream
	_sfx_player.play()


func _make_tone_stream(frequency: float, duration: float, volume: float, should_loop: bool) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var fade: float = 1.0
		if not should_loop:
			var progress: float = float(i) / float(maxi(sample_count - 1, 1))
			fade = minf(progress * 18.0, 1.0) * minf((1.0 - progress) * 10.0, 1.0)

		var wave: float = sin(TAU * frequency * float(i) / float(sample_rate))
		var sample: int = int(clampf(wave * volume * fade, -1.0, 1.0) * 32767.0)
		if sample < 0:
			sample += 65536
		data[i * 2] = sample & 0xff
		data[i * 2 + 1] = (sample >> 8) & 0xff

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	if should_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream
