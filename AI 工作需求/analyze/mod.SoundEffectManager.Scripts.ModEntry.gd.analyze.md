# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod("SoundEffectManager", "play_se", "res://xxx.wav")
   result = GameCore.ModManager.call_mod("SoundEffectManager", "play_bgm", "res://xxx.mp3")
   result = GameCore.ModManager.call_mod("SoundEffectManager", "play_voice", "res://xxx.ogg")
   ```

## 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

## 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
SoundEffectManager

## 模块路径
res://mods/SoundEffectManager/Scripts/ModEntry.gd

## 模块功能
音效管理模块，管理游戏中的音频播放，支持 SE（短音效）、BGM（背景音乐）、Voice（语音）三种类型

## 涉及模块
- ModInterface: 基础接口

# 成员变量

- se_player: AudioStreamPlayer
   - 短音效播放器

- bgm_player: AudioStreamPlayer
   - 背景音乐播放器

- voice_player: AudioStreamPlayer
   - 语音播放器

- current_bgm_path: String
   - 当前 BGM 路径（用于避免重复播放）

# 成员方法

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 创建三个音频播放器节点
      - 设置 BGM 循环播放
      - 启动清理线程

- _on_mod_init() -> void
   - @return void
   - 功能说明：
      - 模块初始化

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用

- _on_mod_disable() -> void
   - @return void
   - 功能说明：
      - 模块禁用
      - 停止所有声音

- _on_mod_unload() -> void
   - @return void
   - 功能说明：
      - 模块卸载

- _load_audio(path: String) -> AudioStream
   - @param path: 音频资源路径
   - @return AudioStream: 音频流
   - 功能说明：
      - 加载音频资源
      - 验证路径是否存在

- play_se(path: String) -> void
   - @param path: 音频资源路径
   - @return void
   - 功能说明：
      - 播放短音效（SE）
      - 不循环，播放一次

- play_bgm(path: String, fade_time: float = 0.5) -> void
   - @param path: 音频资源路径
   - @param fade_time: 淡入淡出时间
   - @return void
   - 功能说明：
      - 播放背景音乐（BGM）
      - 避免重复播放同一 BGM
      - 淡出旧 BGM，淡入新 BGM

- play_voice(path: String) -> void
   - @param path: 音频资源路径
   - @return void
   - 功能说明：
      - 播放语音

- _fade_in(player: AudioStreamPlayer, time: float) -> void
   - @param player: 音频播放器
   - @param time: 淡入时间
   - @return void
   - 功能说明：
      - 音频淡入效果

- _fade_out(player: AudioStreamPlayer, time: float) -> void
   - @param player: 音频播放器
   - @param time: 淡出时间
   - @return void
   - 功能说明：
      - 音频淡出效果

# 数据文件

- ModuleConfig.json: 模块配置文件
