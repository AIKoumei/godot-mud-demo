# core.Scripts.Settings.Settings.gd 分析文档

## 基础规则

### 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

### 基础代码调用用例

- 数组去重
   ```gdscript
   new_array = GameCore.ArrayTools.deduplicate(array)
   ```

- 字典合并
   ```gdscript
   new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
   ```

- 时间获取
   ```gdscript
   time_string =  Time.get_datetime_string_from_system()
   ```

- 调用其他模块
   ```gdscript
   result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
   ```

### 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

### 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
Settings

## 模块路径
res/core/Scripts/Settings/Settings.gd

## 模块功能
设置根类，作为所有设置的容器和全局访问点。主要职责包括:
1. 持有 GameSettings 实例
2. 提供全局可访问的设置接口
3. 扩展其他设置类别的入口

## 模块依赖
- _GameSettings: 游戏设置类

## 数据结构

### Settings 结构
```gdscript
{
  "GameSettings": _GameSettings  # 游戏设置实例
}
```

## 模块用例

```gdscript
# 示例 1：访问游戏设置
var game_settings = GameCore.Settings.GameSettings
print("世界种子：%d" % game_settings.WorldSeed)

# 示例 2：直接访问游戏设置属性
var seed = GameCore.Settings.GameSettings.WorldSeed
var slot = GameCore.Settings.GameSettings.GameSlot

# 示例 3：设置游戏设置
GameCore.Settings.GameSettings.WorldSeed = 12345
GameCore.Settings.GameSettings.GameSlot = 1

# 示例 4：创建新的 Settings 实例
var settings = _Settings.new()
var new_game_settings = _GameSettings.new()
settings.GameSettings = new_game_settings
```

# 成员变量

- var GameSettings = _GameSettings.new()
  - 游戏设置实例
  - 自动创建新的 _GameSettings 对象
  - 包含 WorldSeed, GameSlot, PlayerSpawnMapId, PlayerSpawnMapPosition

# 成员方法

- 无 (纯容器类)

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- _GameSettings: 创建游戏设置实例

## 被其他模块调用
- GameCore: 持有 Settings 实例
- 所有模块：通过 GameCore.Settings 访问设置

## 发送的事件
- 无

# 核心流程

## 初始化流程
```
1. 创建 _Settings 实例
2. 自动创建 _GameSettings 实例
3. 赋值给 GameSettings 变量
4. 通过 GameCore.Settings 全局访问
```

## 访问流程
```
1. 模块访问 GameCore.Settings.GameSettings
2. 获取 _GameSettings 实例
3. 读取或修改属性
4. 设置自动生效
```

# 架构设计

## 容器模式
- 作为设置的容器
- 持有 GameSettings 实例
- 易于扩展其他设置类别

## 全局访问点
- 通过 GameCore.Settings 全局访问
- 所有模块共享同一实例
- 确保设置一致性

## 扩展性设计
- 可添加其他设置类别:
  - GraphicsSettings: 图形设置
  - AudioSettings: 音频设置
  - InputSettings: 输入设置
  - NetworkSettings: 网络设置

# 使用场景

## 1. 全局设置访问
- 所有模块通过 Settings 访问设置
- 统一的访问接口
- 便于管理和维护

## 2. 设置持久化
- 通过 Settings 保存所有设置
- 支持导入/导出
- 跨会话保持

## 3. 设置验证
- 集中验证所有设置
- 确保设置有效性
- 防止无效设置

# TODO

- [ ] 添加更多设置类别
  - [ ] GraphicsSettings: 图形设置
  - [ ] AudioSettings: 音频设置
  - [ ] InputSettings: 输入设置
  - [ ] NetworkSettings: 网络设置

- [ ] 添加设置验证
  - [ ] validate_settings()
  - [ ] 检查设置有效性

- [ ] 添加设置重置
  - [ ] reset_to_defaults()
  - [ ] 重置所有设置为默认值

- [ ] 支持设置导入/导出
  - [ ] save_settings(path)
  - [ ] load_settings(path)
