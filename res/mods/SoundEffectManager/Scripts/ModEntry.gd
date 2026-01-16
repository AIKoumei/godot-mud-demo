## ---------------------------------------------------------
## SoundEffectManager 模块（ModInterface 版本）
##
## 功能说明：
## - 管理游戏中的音频播放
## - 支持三种音频类型：SE（短音效）、BGM（背景音乐）、Voice（语音）
## - 提供 BGM 淡入淡出效果
## - 避免重复播放同一 BGM
## - 支持音频资源加载和管理
## - 提供统一的音频播放接口
##
## 依赖：
## - ModInterface（基础接口）
##
## 调用方式（其他 Mod）：
## GameCore.mod_manager.call_mod("SoundEffectManager", "play_se", "res://xxx.wav")
## GameCore.mod_manager.call_mod("SoundEffectManager", "play_bgm", "res://xxx.mp3")
## GameCore.mod_manager.call_mod("SoundEffectManager", "play_voice", "res://xxx.ogg")
##
## ---------------------------------------------------------
extends ModInterface

# ---------------------------------------------------------
# 内部播放器
# ---------------------------------------------------------
var se_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer

# 当前 BGM 路径（用于避免重复播放）
var current_bgm_path := ""


# ---------------------------------------------------------
# 生命周期：模块加载（脚本挂载后，进入场景树前）
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	var is_load_succeed = super._on_mod_load()

	# 创建播放器节点
	se_player = AudioStreamPlayer.new()
	bgm_player = AudioStreamPlayer.new()
	voice_player = AudioStreamPlayer.new()

	# BGM 默认循环
	bgm_player.stream_paused = false
	bgm_player.autoplay = false

	# 添加到模块节点下
	add_child(se_player)
	add_child(bgm_player)
	add_child(voice_player)

	print("[SoundEffectManager] Players created")
	
	return is_load_succeed


# ---------------------------------------------------------
# 生命周期：模块初始化（进入场景树，_ready）
# ---------------------------------------------------------
func _on_mod_init() -> void:
	super._on_mod_init()
	print("[SoundEffectManager] Initialized")


# ---------------------------------------------------------
# 生命周期：模块启用
# ---------------------------------------------------------
func _on_mod_enable() -> void:
	super._on_mod_enable()
	print("[SoundEffectManager] Enabled")


# ---------------------------------------------------------
# 生命周期：模块禁用
# ---------------------------------------------------------
func _on_mod_disable() -> void:
	super._on_mod_disable()
	print("[SoundEffectManager] Disabled")

	# 停止所有声音
	se_player.stop()
	bgm_player.stop()
	voice_player.stop()


# ---------------------------------------------------------
# 生命周期：模块卸载
# ---------------------------------------------------------
func _on_mod_unload() -> void:
	super._on_mod_unload()
	print("[SoundEffectManager] Unloaded")


# ---------------------------------------------------------
# 工具：加载音频资源
# ---------------------------------------------------------
func _load_audio(path: String) -> AudioStream:
	if path == "":
		return null

	# 默认接收绝对路径
	if not path.begins_with("res://"):
		push_warning("[%s] 不是绝对路径" % [mod_name])
		return null
	## 如果是相对路径，则从 mod 目录加载
	#if not path.begins_with("res://"):
		#path = "%s/%s" % [mod_config.get("audio_root", mod_path()), path]

	if not ResourceLoader.exists(path):
		push_warning("[SoundEffectManager] Audio not found: %s" % path)
		return null

	return load(path)


# ---------------------------------------------------------
# 外部访问：播放 SE（短音效）
# ---------------------------------------------------------
func play_se(path: String) -> void:
	var stream = _load_audio(path)
	if stream:
		se_player.stream = stream
		se_player.play()


# ---------------------------------------------------------
# 外部访问：播放 BGM（背景音乐，含淡入）
# ---------------------------------------------------------
func play_bgm(path: String, fade_time := 0.5) -> void:
	if path == current_bgm_path:
		return

	var stream = _load_audio(path)
	if not stream:
		return

	current_bgm_path = path

	# 淡出旧 BGM
	if bgm_player.playing:
		_fade_out(bgm_player, fade_time)

	# 设置新 BGM
	bgm_player.stream = stream
	bgm_player.volume_db = -40  # 初始低音量
	bgm_player.play()

	# 淡入
	_fade_in(bgm_player, fade_time)


# ---------------------------------------------------------
# 外部访问：播放语音（Voice）
# ---------------------------------------------------------
func play_voice(path: String) -> void:
	var stream = _load_audio(path)
	if stream:
		voice_player.stream = stream
		voice_player.play()


# ---------------------------------------------------------
# 淡入淡出工具
# ---------------------------------------------------------
func _fade_in(player: AudioStreamPlayer, time: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", 0, time)


func _fade_out(player: AudioStreamPlayer, time: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -40, time)
	tween.tween_callback(func(): player.stop())
