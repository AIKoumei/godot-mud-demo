# mod.WorldMapGenerator.Scripts.ModEntry.gd 分析文档

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
WorldMapGenerator

## 模块路径
res/mods/WorldMapGenerator/Scripts/ModEntry.gd

## 模块功能
世界地图生成器模块，负责使用 SimplyMudTownGen 生成所有 location 的城镇地图数据。主要职责包括:
1. 使用线程异步生成所有 location 的地图
2. 调用 SimplyMudTownGen.generate_town() 生成城镇
3. 管理地图生成线程和互斥锁
4. 发送地图生成完成事件
5. 支持调试模式下的缓存保存/加载

## 模块依赖
- SimplyMudTownGen: 城镇生成器
- LocationManager: 获取所有 location 列表
- SaveManager: 保存/加载地图数据缓存
- GameCore.Settings.GameSettings.WorldSeed: 全局种子
- ModEventListenerFilter: 事件监听过滤

## 数据结构

### 地图数据结构
```json
{
  "name": "location_name",
  "map_data": {
    "nodes": {...},
    "center": {...},
    "mask": {...},
    "edge": {...},
    "main_road": {...},
    "secondary_roads": {...},
    "gate": {...},
    "gate_wall": {...},
    "blocks": [...]
  }
}
```

## 模块用例

```gdscript
# 示例 1：生成所有 location 地图
WorldMapGenerator.gen_all_location_map()

# 示例 2：获取所有地图数据
var all_maps = WorldMapGenerator.get_all_map_datas()

# 示例 3：监听地图生成完成事件
# 接收 after_one_location_generate_finished 事件
# 接收 after_gen_all_location_map_finished 事件

# 示例 4：调试模式下从缓存加载
# 如果调试模式且缓存文件存在，自动从缓存加载
```

# 成员变量

- map_gen_thread: Thread
  - 地图生成线程
  - 用于异步生成地图，避免阻塞主线程

- map_gen_thread_mutex: Mutex
  - 互斥锁
  - 保证地图数据在多线程环境下的安全性

- total_location_map_datas: Dictionary
  - 存储所有生成的地图数据
  - 数据结构：{location_name: map_data}

- cur_location_map_data: Dictionary
  - 存储当前正在生成的地图数据
  - 用于事件发送

- is_thread_running: bool
  - 标记线程是否正在运行
  - 防止重复启动线程

# 成员方法

## 生命周期方法

- _on_mod_load() -> bool
  - @return bool: 模块加载是否成功
  - functions:
    - 调用父类 _on_mod_load()
    - 返回加载成功标志

- _on_mod_init() -> void
  - functions:
    - 调用父类 _on_mod_init()
    - 可以读取配置、初始化数据、注册事件等

- _on_mod_enable() -> void
  - functions:
    - 调用父类 _on_mod_enable()
    - 入口场景已经实例化，可以开始逻辑

- _on_mod_disable() -> void
  - functions:
    - 调用父类 _on_mod_disable()
    - 清理 UI、暂停逻辑等

- _on_mod_unload() -> void
  - functions:
    - 调用父类 _on_mod_unload()
    - 清理资源、断开信号、保存数据等

- _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
  - @args:
    - _mod_name: 触发事件的模块名称
    - event_name: 事件名称
    - event_data: 事件数据
  - functions:
    - 调用父类 _on_mod_event()
    - 处理其他模块发送的事件

## 地图生成方法

- _gen_all_location_map() -> void
  - functions:
    - 1. 调用 LocationManager.get_all_locations() 获取所有 location
    - 2. 遍历每个 location:
       - 生成配置：SimplyMudTownGen.gen_config({"seed": WorldSeed})
       - 生成城镇：SimplyMudTownGen.generate_town(cfg)
       - 转换为字典：data.to_dict()
       - 加锁保护数据
       - 存储到 total_location_map_datas
       - 解锁
       - 发送 after_one_location_generate_finished 事件 (延迟调用)
    - 3. 所有 location 生成完成后:
       - 如果是调试模式且缓存文件不存在，保存缓存
       - 发送 after_gen_all_location_map_finished 事件 (延迟调用)
    - 4. 设置 is_thread_running = false

- gen_all_location_map() -> void
  - functions:
    - 1. 检查线程是否正在运行，是则直接返回
    - 2. 如果是调试模式且缓存文件存在:
       - 从缓存加载 total_location_map_datas
       - 遍历缓存数据，发送 after_one_location_generate_finished 事件
       - 发送 after_gen_all_location_map_finished 事件
       - 返回
    - 3. 设置 is_thread_running = true
    - 4. 启动线程：map_gen_thread.start(_gen_all_location_map)

## 数据访问方法

- get_all_map_datas() -> Dictionary
  - @return Dictionary: 所有地图数据
  - functions:
    - 返回 total_location_map_datas

## 事件发送方法

- after_one_location_generate_finished(data) -> void
  - @args:
    - data: 单个 location 的地图数据
  - functions:
    - 发送 after_one_location_generate_finished 事件
    - 事件数据：{location_name, location_map_data}

- after_gen_all_location_map_finished() -> void
  - functions:
    - 如果是调试模式且缓存文件不存在:
      - 保存 total_location_map_datas 到缓存
    - 发送 after_gen_all_location_map_finished 事件 (延迟调用)
    - 事件数据：{location_map_count, location_map_datas}

# 数据文件

- 缓存文件 (调试模式)
  - 路径：{mod_slot}/WorldMapGenerator/total_location_map_datas.sav
  - 格式：二进制存档文件
  - 内容：total_location_map_datas 字典

# 模块交互

## 调用的其他模块
- LocationManager: get_all_locations() 获取 location 列表
- SimplyMudTownGen: gen_config(), generate_town() 生成城镇
- SaveManager: save_mod_slot_data(), load_mod_slot_data(), has_mod_slot_file()
- ModEventListenerFilter: 事件监听过滤

## 被其他模块调用
- WorldMapManager: 监听 after_gen_all_location_map_finished 事件
- GameManager: 调用 gen_all_location_map() 生成地图

## 发送的事件
- after_one_location_generate_finished: 单个 location 地图生成完成
- after_gen_all_location_map_finished: 所有 location 地图生成完成

# 核心流程

## 地图生成流程
```
1. GameManager 调用 gen_all_location_map()
2. 检查线程是否运行
   - 运行中：直接返回
3. 检查调试模式缓存
   - 缓存存在：加载缓存，发送事件，返回
4. 启动地图生成线程
   - is_thread_running = true
   - map_gen_thread.start(_gen_all_location_map)

5. 线程执行 _gen_all_location_map():
   a. 获取所有 location 列表
   b. 遍历每个 location:
      - 生成配置 (使用 WorldSeed)
      - 调用 SimplyMudTownGen.generate_town()
      - 转换为字典格式
      - 加锁保护
      - 存储到 total_location_map_datas
      - 解锁
      - 延迟发送 after_one_location_generate_finished 事件
   c. 所有 location 生成完成:
      - 调试模式：保存缓存
      - 延迟发送 after_gen_all_location_map_finished 事件
   d. 设置 is_thread_running = false

6. 其他模块监听事件:
   - WorldMapManager 监听 after_gen_all_location_map_finished
   - 接收所有地图数据
```

## 线程安全设计
```
1. 使用 Mutex 保护共享数据
   - map_gen_thread_mutex.lock()
   - 修改 total_location_map_datas
   - map_gen_thread_mutex.unlock()

2. 使用 is_thread_running 标记
   - 防止重复启动线程
   - 线程结束时重置标记

3. 使用 call_deferred 发送事件
   - 确保事件在主线程执行
   - 避免跨线程访问 Godot 对象
```

## 缓存机制
```
调试模式下:
1. 第一次生成:
   - 生成所有地图
   - 保存到缓存文件
   - 发送事件

2. 后续运行:
   - 检查缓存文件是否存在
   - 存在：从缓存加载
   - 发送事件
   - 跳过生成过程

优点:
- 加快调试速度
- 避免重复生成
- 保持地图一致性
```

# 架构设计

## 线程架构
- 主线程：游戏逻辑、渲染
- 地图生成线程：异步生成地图数据
- 使用 Mutex 保证数据安全
- 使用 call_deferred 确保线程安全的事件发送

## 事件驱动设计
- 地图生成完成后发送事件
- 其他模块监听事件获取数据
- 松耦合设计，便于扩展

## 缓存策略
- 调试模式启用缓存
- 保存所有地图数据
- 加快调试迭代速度

## 错误处理
- 线程启动前检查是否已运行
- 使用 try-catch 保护关键代码
- 事件发送使用 deferred 避免崩溃

# 使用场景

## 1. 游戏启动
- 新游戏时生成所有地图
- 使用缓存加速调试
- 确保地图数据可用

## 2. 程序化生成
- 使用 WorldSeed 确保可重复
- 异步生成避免卡顿
- 事件通知其他模块

## 3. 调试模式
- 缓存地图数据
- 快速迭代测试
- 保持一致性

# TODO

- [ ] 添加进度报告
  - [ ] 生成进度百分比
  - [ ] 显示当前 location

- [ ] 优化线程管理
  - [ ] 线程池
  - [ ] 并行生成多个 location

- [ ] 添加错误处理
  - [ ] 生成失败重试
  - [ ] 异常捕获

- [ ] 支持增量生成
  - [ ] 只生成未生成的 location
  - [ ] 按需生成

- [ ] 优化缓存
  - [ ] 压缩缓存文件
  - [ ] 版本管理
