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
var pad_phase := 0.0
var sample_cursor := 0

var tracks := [
	[392.00, 440.00, 523.25, 587.33, 659.25, 587.33, 523.25, 440.00],
	[261.63, 293.66, 392.00, 440.00, 523.25, 440.00, 392.00, 293.66],
	[293.66, 392.00, 440.00, 523.25, 587.33, 523.25, 440.00, 392.00],
]
var track_bass := [196.00, 130.81, 146.83]
var track_note_lengths := [0.78, 0.62, 0.92]

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
		phase = 0.0
		bass_phase = 0.0
		pad_phase = 0.0

func set_track(index: int) -> void:
	current_track = clampi(index, 0, tracks.size() - 1)
	sample_cursor = 0
	phase = 0.0
	bass_phase = 0.0
	pad_phase = 0.0

func _process(_delta: float) -> void:
	if not music_enabled or playback == null:
		return
	var frames := playback.get_frames_available()
	for _frame in range(frames):
		var note_length := int(MIX_RATE * track_note_lengths[current_track])
		var note_index := int(sample_cursor / note_length)
		var local_sample := sample_cursor % note_length
		var frequency: float = tracks[current_track][note_index % tracks[current_track].size()]
		var note_progress := float(local_sample) / float(note_length)
		var envelope := sin(PI * note_progress)
		envelope = pow(maxf(envelope, 0.0), 1.45)
		phase = fmod(phase + TAU * frequency / MIX_RATE, TAU)
		var bass_frequency: float = track_bass[current_track]
		bass_phase = fmod(bass_phase + TAU * bass_frequency / MIX_RATE, TAU)
		pad_phase = fmod(pad_phase + TAU * (frequency * 0.5) / MIX_RATE, TAU)
		var shimmer := sin(phase) * 0.105 + sin(phase * 2.01) * 0.018 + sin(phase * 3.01) * 0.008
		var pad := sin(pad_phase) * 0.035
		var bass_envelope := 0.72 if note_index % 4 == 0 else 0.3
		var bass := sin(bass_phase) * 0.045 * bass_envelope
		var sample := (shimmer * envelope + pad * envelope * 0.8 + bass * envelope * 0.7) * 0.58
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
			notes = [659.25, 987.77]
			duration = 0.1
			volume = 0.13
		"move":
			notes = [205.0, 329.63]
			duration = 0.13
			volume = 0.24
		"capture":
			notes = [142.0, 196.0, 293.66]
			duration = 0.18
			volume = 0.29
		"win":
			notes = [392.0, 440.0, 523.25, 659.25, 783.99]
			duration = 0.14
			volume = 0.2
		_:
			notes = [440.0]
	var wav := _make_wav(notes, duration, volume, kind)
	var player := AudioStreamPlayer.new()
	player.stream = wav
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _make_wav(notes: Array[float], note_duration: float, volume: float, kind: String) -> AudioStreamWAV:
	var samples_per_note := int(MIX_RATE * note_duration)
	var total_samples := samples_per_note * notes.size()
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	for note_index in range(notes.size()):
		var frequency := notes[note_index]
		for i in range(samples_per_note):
			var t := float(i) / MIX_RATE
			var progress := float(i) / float(samples_per_note)
			var envelope := pow(1.0 - progress, 1.8)
			var sound_frequency := frequency
			if kind == "move" or kind == "capture" or kind == "win":
				sound_frequency = lerpf(frequency * 1.42, frequency * 0.62, progress)
			var wave := sin(TAU * sound_frequency * t) * 0.68 + sin(TAU * sound_frequency * 1.997 * t) * 0.16
			if kind == "select":
				wave = sin(TAU * sound_frequency * t) * 0.78 + sin(TAU * sound_frequency * 2.01 * t) * 0.08
			elif kind == "move":
				wave += exp(-progress * 72.0) * sin(TAU * frequency * 3.8 * t) * 0.22
			elif kind == "capture":
				wave += sin(TAU * frequency * 0.5 * t) * 0.2
			elif kind == "win":
				wave += sin(TAU * sound_frequency * 2.01 * t) * 0.12
			var sample := int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
			bytes.encode_s16((note_index * samples_per_note + i) * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(MIX_RATE)
	wav.stereo = false
	wav.data = bytes
	return wav
