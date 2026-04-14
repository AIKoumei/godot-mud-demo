# core.Scripts.SaveManager.SaveManager.gd 分析文档

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
SaveManager

## 模块路径
res/core/Scripts/SaveManager/SaveManager.gd

## 模块功能
用户数据存取模块，负责游戏存档的保存、加载和管理。采用分层架构设计，包括:
1. 业务逻辑层：保存游戏状态、加载存档、预览信息获取
2. Slot 抽象层：对特定存档位的操作
3. Mod 扩展层：针对 Mod 的专用接口
4. 文件核心层：最底层的 JSON/加密读写实现
5. 工具函数层：路径扫描、物理删除等

## 模块依赖
- DirAccess: 目录访问
- FileAccess: 文件访问
- JSON: JSON 序列化/反序列化
- Time: 时间获取
- OS: 操作系统接口 (删除文件到回收站)

## 数据结构

### 存档位结构
```
user://saves/
├── slot_0/
│   ├── save.sav (加密主存档)
│   ├── info.json (预览信息)
│   └── mods/
│       └── {mod_name}.sav (Mod 存档)
├── slot_1/
└── slot_2/
```

### 预览信息结构
```json
{
  "slot_id": 0,
  "player_name": "勇者",
  "level": 15,
  "save_time": "2023-12-31 12:00:00"
}
```

### 带元数据的存档结构
```json
{
  "metadata": {
    "version": "1.0",
    "generated_at": "2023-12-31 12:00:00",
    "total_units": 5
  },
  "data": {
    "units": {...}
  }
}
```

## 模块用例

```gdscript
# 示例 1：保存游戏
SaveManager.save_game(0)  # 保存到 slot_0

# 示例 2：加载游戏
var game_data = SaveManager.load_game(0)

# 示例 3：获取所有存档位信息
var all_info = SaveManager.get_all_save_slots_info()
for info in all_info:
    print("Slot %d: %s (Level %d)" % [info.slot_id, info.player_name, info.level])

# 示例 4：检查存档位是否存在
if SaveManager.has_slot(0):
    print("存档位 0 存在")

# 示例 5：检查存档位文件是否存在
if SaveManager.has_slot_file(0, "save.sav"):
    print("主存档文件存在")

# 示例 6：保存 Mod 数据
var mod_data = {"units": [...]}
SaveManager.save_mod_slot_data(0, "MyMod", mod_data)

# 示例 7：加载 Mod 数据
var mod_data = SaveManager.load_mod_slot_data(0, "MyMod")

# 示例 8：删除存档位
SaveManager.delete_slot(0)

# 示例 9：保存带元数据的数据
var payload = {"units": [...]}
var packet = SaveManager.wrap_data_with_metadata(payload, {
    "version": "1.0",
    "total_units": payload.units.size()
})
SaveManager.save_slot_data(0, "units_state.sav", packet)

# 示例 10：获取可用存档位列表
var available_slots = SaveManager.get_available_slots()
print("可用存档位：%s" % str(available_slots))
```

# 成员变量

## 常量配置
- const DEFAULT_SAVE_PATH = "user://saves"
  - 默认存档路径

- const SECRET_KEY = "YourCustomKey_4.6"
  - 加密密钥
  - 用于加密/解密存档文件

# 成员方法

## 业务逻辑层方法

- save_game(slot_id: int) -> void
  - @args:
    - slot_id: 存档位 ID
  - functions:
    - 获取游戏数据 (TODO: 实现)
    - 保存主存档到 save.sav (加密)
    - 保存预览信息到 info.json (不加密)
    - 预览信息包含：player_name, level, save_time

- load_game(slot_id: int) -> Dictionary
  - @args:
    - slot_id: 存档位 ID
  - @return Dictionary: 加载的游戏数据
  - functions:
    - 从 save.sav 加载主存档 (加密)
    - 如果加载成功，打印信息
    - 返回加载的数据

- get_all_save_slots_info() -> Array[Dictionary]
  - @return Array[Dictionary]: 所有存档位的预览信息数组
  - functions:
    - 调用 get_available_slots() 获取所有可用 ID
    - 对每个 ID 调用 load_game_slot_info()
    - 如果信息为空，返回默认"损坏或无数据"信息
    - 返回所有信息数组

- load_game_slot_info(slot_id: int) -> Dictionary
  - @args:
    - slot_id: 存档位 ID
  - @return Dictionary: 预览信息
  - functions:
    - 从 info.json 加载预览数据
    - 注入 slot_id 到信息中
    - 返回信息字典

## Slot 抽象层方法

- has_slot(slot_id: int) -> bool
  - @args:
    - slot_id: 存档位 ID
  - @return bool: 存档位是否存在
  - functions:
    - 检查 slot_{id} 目录是否存在

- has_slot_file(slot_id: int, filepath: String) -> bool
  - @args:
    - slot_id: 存档位 ID
    - filepath: 文件路径 (相对于 slot 目录)
  - @return bool: 文件是否存在
  - functions:
    - 构建完整路径
    - 检查文件是否存在

- has_mod_slot_file(slot_id: int, filepath: String) -> bool
  - @args:
    - slot_id: 存档位 ID
    - filepath: 文件路径 (相对于 mods 目录)
  - @return bool: Mod 文件是否存在
  - functions:
    - 构建 mods/{filepath} 路径
    - 检查文件是否存在

- save_slot_data(slot_id: int, filepath: String, data: Dictionary, encrypt: bool = false) -> Error
  - @args:
    - slot_id: 存档位 ID
    - filepath: 文件路径
    - data: 要保存的数据
    - encrypt: 是否加密，默认 false
  - @return Error: 保存结果
  - functions:
    - 构建完整路径
    - 调用 save_dict_to_path() 保存

- load_slot_data(slot_id: int, filepath: String, encrypt: bool = false) -> Dictionary
  - @args:
    - slot_id: 存档位 ID
    - filepath: 文件路径
    - encrypt: 是否加密，默认 false
  - @return Dictionary: 加载的数据
  - functions:
    - 构建完整路径
    - 调用 load_dict_from_path() 加载

- delete_slot(slot_id: int) -> void
  - @args:
    - slot_id: 存档位 ID
  - functions:
    - 检查目录是否存在
    - 尝试移动到回收站 (OS.move_to_trash)
    - 如果失败，递归物理删除
    - 打印删除信息

## Mod 扩展层方法

- save_mod_slot_data(slot_id: int, mod_name: String, data: Dictionary, encrypt: bool = false) -> Error
  - @args:
    - slot_id: 存档位 ID
    - mod_name: Mod 名称
    - data: 要保存的数据
    - encrypt: 是否加密，默认 false
  - @return Error: 保存结果
  - functions:
    - 保存到 mods/{mod_name}.sav
    - 调用 save_slot_data()

- load_mod_slot_data(slot_id: int, mod_name: String, encrypt: bool = false) -> Dictionary
  - @args:
    - slot_id: 存档位 ID
    - mod_name: Mod 名称
    - encrypt: 是否加密，默认 false
  - @return Dictionary: 加载的数据
  - functions:
    - 从 mods/{mod_name}.sav 加载
    - 调用 load_slot_data()

## 文件核心层方法

- save_dict_to_path(data: Dictionary, path: String, encrypt: bool = false) -> Error
  - @args:
    - data: 要保存的字典
    - path: 完整文件路径
    - encrypt: 是否加密，默认 false
  - @return Error: 保存结果
  - functions:
    - 创建目录 (如果不存在)
    - 根据 encrypt 选择打开方式:
      - 加密：FileAccess.open_encrypted_with_pass
      - 不加密：FileAccess.open
    - 序列化 JSON: JSON.stringify(data, "\t")
    - 写入文件
    - 关闭文件
    - 返回错误码

- load_dict_from_path(path: String, encrypt: bool = false) -> Dictionary
  - @args:
    - path: 完整文件路径
    - encrypt: 是否加密，默认 false
  - @return Dictionary: 加载的字典
  - functions:
    - 检查文件是否存在
    - 根据 encrypt 选择打开方式
    - 读取文件内容
    - 关闭文件
    - 解析 JSON
    - 如果是 Dictionary，返回数据
    - 否则返回空字典

## 工具函数层方法

- get_available_slots() -> Array[int]
  - @return Array[int]: 可用存档位 ID 数组
  - functions:
    - 扫描 user://saves/ 目录
    - 查找所有 slot_ 开头的目录
    - 提取 ID 并排序
    - 返回 ID 数组

- _delete_dir_recursive(path: String) -> void
  - @args:
    - path: 目录路径
  - functions:
    - 打开目录
    - 递归删除所有子目录和文件
    - 最后删除目录本身

## 元数据包装方法

- wrap_data_with_metadata(data: Dictionary, extra_metadata: Dictionary = {}) -> Dictionary
  - @args:
    - data: 要包装的数据
    - extra_metadata: 额外元数据，默认空字典
  - @return Dictionary: 包装后的数据
  - functions:
    - 创建基础元数据:
      - version: "1.0"
      - generated_at: 当前时间
    - 合并 extra_metadata
    - 更新 generated_at 时间戳
    - 返回 {"metadata": ..., "data": ...}

- save_current_units(slot_id: int) -> void
  - @args:
    - slot_id: 存档位 ID
  - functions:
    - 构建 payload (TODO: 获取实际单位数据)
    - 调用 wrap_data_with_metadata() 包装
    - 保存到 temp/units_state.sav

# 数据文件

- 存档文件结构
  - user://saves/slot_{id}/save.sav (加密主存档)
  - user://saves/slot_{id}/info.json (预览信息)
  - user://saves/slot_{id}/mods/{mod_name}.sav (Mod 存档)

# 模块交互

## 调用的其他模块
- DirAccess: 目录操作
- FileAccess: 文件操作
- JSON: JSON 序列化/反序列化
- Time: 时间获取
- OS: 系统接口 (删除到回收站)

## 被其他模块调用
- GameManager: 调用 save_game(), load_game()
- Mod 模块：调用 save_mod_slot_data(), load_mod_slot_data()
- UI 模块：调用 get_all_save_slots_info()

## 发送的事件
- 无

# 核心流程

## 保存游戏流程
```
1. 调用 save_game(slot_id)
2. 获取游戏数据 (TODO)
3. 保存主存档到 slot_{id}/save.sav (加密)
4. 保存预览信息到 slot_{id}/info.json:
   - player_name: "勇者"
   - level: 15
   - save_time: 当前时间
5. 完成保存
```

## 加载游戏流程
```
1. 调用 load_game(slot_id)
2. 从 slot_{id}/save.sav 加载 (加密)
3. 如果加载成功，打印信息
4. 返回游戏数据
```

## 获取存档列表流程
```
1. 调用 get_all_save_slots_info()
2. 调用 get_available_slots() 获取 ID 列表
3. 对每个 ID:
   - 调用 load_game_slot_info()
   - 如果为空，填充默认信息
4. 返回所有信息数组
```

## Mod 存档流程
```
1. Mod 调用 save_mod_slot_data(slot_id, mod_name, data)
2. 保存到 slot_{id}/mods/{mod_name}.sav
3. 返回保存结果

4. Mod 调用 load_mod_slot_data(slot_id, mod_name)
5. 从 slot_{id}/mods/{mod_name}.sav 加载
6. 返回加载的数据
```

## 加密/解密流程
```
加密保存:
1. 使用 SECRET_KEY
2. FileAccess.open_encrypted_with_pass(path, WRITE, SECRET_KEY)
3. 写入 JSON 字符串
4. 关闭文件

解密加载:
1. 使用 SECRET_KEY
2. FileAccess.open_encrypted_with_pass(path, READ, SECRET_KEY)
3. 读取 JSON 字符串
4. 解析 JSON
5. 返回字典
```

## 删除存档流程
```
1. 调用 delete_slot(slot_id)
2. 检查目录是否存在
3. 尝试移动到回收站:
   - OS.move_to_trash(globalize_path)
4. 如果失败，递归物理删除:
   - _delete_dir_recursive()
5. 打印删除信息
```

# 架构设计

## 分层架构
1. **业务逻辑层**: 高层业务接口 (save_game, load_game)
2. **Slot 抽象层**: 存档位操作 (save_slot_data, load_slot_data)
3. **Mod 扩展层**: Mod 专用接口 (save_mod_slot_data)
4. **文件核心层**: 底层 IO (save_dict_to_path, load_dict_from_path)
5. **工具函数层**: 辅助函数 (get_available_slots, _delete_dir_recursive)

## 目录结构
```
user://saves/
├── slot_0/
│   ├── save.sav (加密)
│   ├── info.json (明文)
│   └── mods/
│       ├── ModA.sav
│       └── ModB.sav
├── slot_1/
└── slot_2/
```

## 安全设计
- 使用加密密钥保护主存档
- Mod 存档可选择加密
- 预览信息使用明文 (便于快速读取)
- 删除时先尝试回收站，失败后物理删除

## 性能优化
- 预览信息单独存储 (快速读取列表)
- 主存档加密 (保护核心数据)
- 按需加载 (只加载需要的文件)

# 使用场景

## 1. 游戏存档
- 保存游戏进度
- 加载游戏
- 多存档位管理

## 2. Mod 数据持久化
- Mod 专用存档
- 独立于主存档
- 支持多个 Mod

## 3. UI 展示
- 存档列表
- 预览信息
- 存档状态

## 4. 数据管理
- 存档删除
- 存档检查
- 文件管理

# TODO

- [ ] 实现 save_game() 中的游戏数据获取
- [ ] 添加存档压缩功能
- [ ] 支持存档备份
- [ ] 添加存档验证 (校验和)
- [ ] 支持异步保存/加载
- [ ] 添加存档版本迁移
- [ ] 优化加密密钥管理
- [ ] 添加存档自动保存
