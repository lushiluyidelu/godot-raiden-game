extends Node

# 音效播放器
var shoot_sound: AudioStreamPlayer
var explosion_sound: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

func _ready():
	# 创建射击音效播放器
	shoot_sound = AudioStreamPlayer.new()
	shoot_sound.stream = _create_shoot_sound()
	add_child(shoot_sound)

	# 创建爆炸音效播放器
	explosion_sound = AudioStreamPlayer.new()
	explosion_sound.stream = _create_explosion_sound()
	add_child(explosion_sound)

	# 创建背景音乐播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = _create_bgm_sound()
	add_child(bgm_player)

	print("[SoundManager] 初始化完成")

func play_shoot_sound():
	shoot_sound.pitch_scale = randf_range(0.9, 1.1)
	shoot_sound.play()

func play_explosion_sound():
	explosion_sound.pitch_scale = randf_range(0.8, 1.2)
	explosion_sound.play()

func start_bgm():
	bgm_player.volume_db = -15
	bgm_player.stream.loop = true  # 启用循环
	bgm_player.play()
	print("[SoundManager] 背景音乐开始")

func _create_shoot_sound() -> AudioStream:
	var sample_rate = 22050
	var length = 0.1
	var byte_data = PackedByteArray()
	for i in range(int(sample_rate * length)):
		var t = float(i) / sample_rate
		var freq = 1500 * exp(-t * 15)
		var amp = exp(-t * 25) * 0.3
		var s = sin(t * freq * TAU) * amp
		# 转换为 16 位整数
		var val = int(s * 32767)
		byte_data.append(val & 0xFF)
		byte_data.append((val >> 8) & 0xFF)

	var wav = AudioStreamWAV.new()
	wav.set_data(byte_data)
	return wav

func _create_explosion_sound() -> AudioStream:
	var sample_rate = 22050
	var length = 0.2
	var byte_data = PackedByteArray()
	for i in range(int(sample_rate * length)):
		var t = float(i) / sample_rate
		var amp = exp(-t * 8) * 0.4
		var noise = randf_range(-1, 1) * 0.7
		var low = sin(t * 80 * TAU) * 0.3
		var s = (noise + low) * amp
		var val = int(s * 32767)
		byte_data.append(val & 0xFF)
		byte_data.append((val >> 8) & 0xFF)

	var wav = AudioStreamWAV.new()
	wav.set_data(byte_data)
	return wav

func _create_bgm_sound() -> AudioStream:
	var bgm = load("res://assets/music/bgm.mp3")
	if bgm == null:
		print("[SoundManager] 警告：BGM 文件加载失败！")
	return bgm
