# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod("CachePoolManager", "get_cached_object", {
       "key": "res://xxx.tscn",
       "key_type": "path"
   })
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
CachePoolManager

## 模块路径
res://mods/CachePoolManager/Scripts/ModEntry.gd

## 模块功能
缓存池管理模块，提供对象缓存池管理功能，支持多种缓存类型，自动清理过期缓存对象

## 涉及模块
- ModInterface: 基础接口

# 成员变量

- DEFAULT_CACHE_TIMEOUT: float = 300.0
   - 默认缓存超时时间（秒）

- DEFAULT_MAX_CACHE_SIZE: int = 10
   - 默认最大缓存大小

- CLEANUP_INTERVAL: float = 1.0
   - 清理间隔（秒）

- _cached_objects: Dictionary
   - 缓存对象字典：
   ```json
   {
      "path": {},
      "type": {},
      "script": {},
      "custom": {}
   }
   ```

- _cache_config: Dictionary
   - 缓存配置：
   ```json
   {
      "timeout": 300.0,
      "max_size": 10
   }
   ```

- _cleanup_thread: Thread
   - 清理线程

- _cleanup_mutex: Mutex
   - 清理互斥锁

- _cleanup_running: bool
   - 清理线程运行标志

- _pending_free: Array[Object]
   - 待释放对象数组

- _cleanup_timer: float
   - 清理计时器

# 成员方法

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 初始化缓存对象字典
      - 初始化缓存配置
      - 启动清理线程

- _on_mod_unload() -> void
   - @return void
   - 功能说明：
      - 停止清理线程
      - 清空所有缓存

- _process(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 主线程处理 queue_free
      - 定期清理待释放对象

- _thread_cleanup_loop() -> void
   - @return void
   - 功能说明：
      - 后台线程循环清理过期缓存

- _cleanup_expired_cache_thread() -> void
   - @return void
   - 功能说明：
      - 扫描并标记过期缓存
      - 将过期对象加入待释放列表

- cache(key: Variant, object: Object, always_cache: bool = false) -> void
   - @param key: 缓存键
   - @param object: 缓存对象
   - @param always_cache: 是否永久缓存
   - @return void
   - 功能说明：
      - 缓存对象（统一入口）

- get_cached(key: Variant) -> Object
   - @param key: 缓存键
   - @return Object: 缓存对象
   - 功能说明：
      - 获取缓存对象（FIFO）

- _detect_key_type(key: Variant) -> String
   - @param key: 缓存键
   - @return String: 键类型（path/type/script/custom）
   - 功能说明：
      - 识别键类型

- _cache_add(key_type: String, key: Variant, object: Object, always_cache: bool) -> void
   - @param key_type: 键类型
   - @param key: 缓存键
   - @param object: 缓存对象
   - @param always_cache: 是否永久缓存
   - @return void
   - 功能说明：
      - 添加缓存

- _cache_pop(key_type: String, key: Variant) -> Object
   - @param key_type: 键类型
   - @param key: 缓存键
   - @return Object: 缓存对象
   - 功能说明：
      - 弹出缓存对象（FIFO）

- _check_cache_size_limit(key_type: String, key: Variant) -> void
   - @param key_type: 键类型
   - @param key: 缓存键
   - @return void
   - 功能说明：
      - 检查缓存大小限制
      - 超出限制时移除旧缓存

- clear(key: Variant) -> void
   - @param key: 缓存键
   - @return void
   - 功能说明：
      - 清理指定键的缓存

- clear_all() -> void
   - @return void
   - 功能说明：
      - 清理所有缓存

# 数据文件

- ModuleConfig.json: 模块配置文件
