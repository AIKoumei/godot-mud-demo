# core.Scripts.Settings.GameSettings.gd 分析文档

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
GameSettings

## 模块路径
res/core/Scripts/Settings/GameSettings.gd

## 模块功能
游戏设置类，存储游戏运行时配置和全局状态。主要职责包括:
1. 存储世界种子 (WorldSeed)
2. 管理存档位 (GameSlot)
3. 定义玩家出生点 (PlayerSpawnMapId, PlayerSpawnMapPosition)
4. 提供全局可访问的设置接口

## 模块依赖
- randi(): 随机数生成

## 数据结构

### GameSettings 结构
```gdscript
{
  "WorldSeed": int,           # 世界生成种子
  "GameSlot": int,            # 当前存档位
  "PlayerSpawnMapId": String, # 出生地图 ID
  "PlayerSpawnMapPosition": Vector2i  # 出生位置
}
```

## 模块用例

```gdscript
# 示例 1：访问世界种子
var seed = GameCore.Settings.GameSettings.WorldSeed
print("世界种子：%d" % seed)

# 示例 2：设置新的世界种子
GameCore.Settings.GameSettings.WorldSeed = 12345

# 示例 3：获取当前存档位
var slot = GameCore.Settings.GameSettings.GameSlot
print("当前存档位：%d" % slot)

# 示例 4：设置玩家出生点
GameCore.Settings.GameSettings.PlayerSpawnMapId = "file_island"
GameCore.Settings.GameSettings.PlayerSpawnMapPosition = Vector2i(10, 10)

# 示例 5：新游戏时重置设置
GameCore.Settings.GameSettings.WorldSeed = randi()
GameCore.Settings.GameSettings.GameSlot = 0
GameCore.Settings.GameSettings.PlayerSpawnMapId = ""
GameCore.Settings.GameSettings.PlayerSpawnMapPosition = Vector2i.ZERO
```

# 成员变量

## 导出变量 (@export)

- @export var WorldSeed = randi()
  - 世界生成种子
  - 默认值：随机数
  - 用于程序化内容生成 (地图、城镇等)
  - 确保可重复生成相同的世界

- @export var GameSlot = 0
  - 当前存档位
  - 默认值：0
  - 用于 SaveManager 保存/加载

- @export var PlayerSpawnMapId = ""
  - 玩家出生地图 ID
  - 默认值：空字符串
  - 用于 WorldMapInstanceManager 加载出生地图

- @export var PlayerSpawnMapPosition = Vector2i.ZERO
  - 玩家出生地图位置
  - 默认值：(0, 0)
  - 用于 WorldSceneManager 生成玩家节点

# 成员方法

- 无 (纯数据类，使用 @export 变量)

# 数据文件

- 无直接依赖的数据文件
- 通过 Settings.gd 持久化到配置文件

# 模块交互

## 调用的其他模块
- 无

## 被其他模块调用
- WorldMapGenerator: 读取 WorldSeed 生成地图
- SaveManager: 读取 GameSlot 保存/加载
- WorldMapInstanceManager: 读取 PlayerSpawnMapId 和 PlayerSpawnMapPosition
- GameManager: 设置出生点

## 发送的事件
- 无

# 核心流程

## 新游戏初始化流程
```
1. 创建新游戏
2. 生成新的 WorldSeed (或使用玩家输入)
3. 设置 GameSlot = 0
4. 设置 PlayerSpawnMapId = 起始地图 ID
5. 设置 PlayerSpawnMapPosition = 起始位置
6. 开始游戏
```

## 世界生成流程
```
1. WorldMapGenerator 读取 WorldSeed
2. 使用种子初始化随机数生成器
3. 生成地图 (确保可重复)
4. 保存地图数据
```

## 玩家出生流程
```
1. WorldMapInstanceManager 读取 PlayerSpawnMapId
2. 加载对应的地图实例
3. 读取 PlayerSpawnMapPosition
4. 在指定位置生成玩家节点
5. 设置摄像机跟随玩家
```

# 架构设计

## 单例模式
- 通过 GameCore.Settings.GameSettings 全局访问
- 所有模块共享同一实例
- 确保设置一致性

## 导出变量设计
- 使用 @export 导出变量
- 可在 Inspector 中可视化配置
- 便于调试和测试

## 数据持久化
- 通过 Settings.gd 保存到配置文件
- 支持保存和加载
- 跨会话保持设置

## 默认值设计
- WorldSeed: 随机数 (每次运行不同)
- GameSlot: 0 (第一个存档位)
- PlayerSpawnMapId: 空字符串 (需要设置)
- PlayerSpawnMapPosition: Vector2i.ZERO (原点)

# 使用场景

## 1. 新游戏设置
- 生成世界种子
- 选择存档位
- 设置出生点

## 2. 程序化生成
- 使用 WorldSeed 确保可重复
- 地图生成
- 城镇生成

## 3. 存档管理
- 使用 GameSlot 标识存档位
- 保存游戏状态
- 加载游戏

## 4. 玩家出生
- 读取出生地图 ID
- 读取出生位置
- 生成玩家节点

# TODO

- [ ] 添加更多游戏设置
  - [ ] 难度设置
  - [ ] 图形设置
  - [ ] 音频设置

- [ ] 支持设置验证
  - [ ] 检查 WorldSeed 有效性
  - [ ] 检查 GameSlot 范围

- [ ] 添加设置重置功能
  - [ ] 重置为默认值
  - [ ] 清除所有设置

- [ ] 支持设置导入/导出
  - [ ] 保存设置到文件
  - [ ] 从文件加载设置
