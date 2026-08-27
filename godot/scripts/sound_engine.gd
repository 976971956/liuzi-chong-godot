extends Node

const MIX_RATE := 22050.0

var music_enabled := false
var sfx_enabled := true
var current_track := 0
var music_player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var bass_phase := 0.0
var sample_cursor := 0

var tracks := [
	[392.00, 440.00, 523.25, 440.00, 349.23, 392.00, 293.66, 349.23],
	[261.63, 329.63, 392.00, 329.63, 293.66, 349.23, 440.00, 349.23],
	[293.66, 392.00, 440.00, 523.25, 440.00, 392.00, 329.63, 293.66],
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -10.0
	add_child(music_player)
	generator = AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.35
	music_player.stream = generator

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if enabled:
		if not music_player.playing:
			music_player.play()
			playback = music_player.get_stream_playback()
	else:
		music_player.stop()
		playback = null
		sample_cursor = 0

func set_track(index: int) -> void:
	current_track = clampi(index, 0, tracks.size() - 1)
	sample_cursor = 0
	phase = 0.0
	bass_phase = 0.0

func _process(_delta: float) -> void:
	if not music_enabled or playback == null:
		return
	var frames := playback.get_frames_available()
	for _frame in range(frames):
		var note_length := int(MIX_RATE * 0.72)
		var note_index := int(sample_cursor / note_length)
		var local_sample := sample_cursor % note_length
		var frequency: float = tracks[current_track][note_index % tracks[current_track].size()]
		var envelope := sin(PI * float(local_sample) / float(note_length))
		envelope = pow(maxf(envelope, 0.0), 1.6)
		phase = fmod(phase + TAU * frequency / MIX_RATE, TAU)
		bass_phase = fmod(bass_phase + TAU * (frequency * 0.5) / MIX_RATE, TAU)
		var shimmer := sin(phase) * 0.12 + sin(phase * 2.01) * 0.025
		var bass := sin(bass_phase) * 0.045
		var sample := (shimmer * envelope + bass * envelope * 0.75) * 0.62
		playback.push_frame(Vector2(sample, sample))
		sample_cursor += 1

func play_sfx(kind: String) -> void:
	if not sfx_enabled:
		return
	var notes: Array[float] = []
	var duration := 0.12
	var volume := 0.28
	match kind:
		"select":
			notes = [520.0]
			duration = 0.07
			volume = 0.16
		"move":
			notes = [260.0, 390.0]
			duration = 0.09
		"capture":
			notes = [180.0, 120.0]
			duration = 0.15
			volume = 0.34
		"win":
			notes = [392.0, 523.25, 659.25, 783.99]
			duration = 0.16
			volume = 0.24
		_:
			notes = [440.0]
	var wav := _make_wav(notes, duration, volume)
	var player := AudioStreamPlayer.new()
	player.stream = wav
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _make_wav(notes: Array[float], note_duration: float, volume: float) -> AudioStreamWAV:
	var samples_per_note := int(MIX_RATE * note_duration)
	var total_samples := samples_per_note * notes.size()
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	for note_index in range(notes.size()):
		var frequency := notes[note_index]
		for i in range(samples_per_note):
			var t := float(i) / MIX_RATE
			var envelope := pow(1.0 - float(i) / float(samples_per_note), 1.8)
			var wave := sin(TAU * frequency * t) * 0.72 + sin(TAU * frequency * 1.997 * t) * 0.18
			var sample := int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
			bytes.encode_s16((note_index * samples_per_note + i) * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(MIX_RATE)
	wav.stereo = false
	wav.data = bytes
	return wav

