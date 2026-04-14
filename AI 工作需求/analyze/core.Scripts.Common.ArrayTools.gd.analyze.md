# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 数组去重
   ```gdscript
   new_array = GameCore.ArrayTools.deduplicate(array)
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
ArrayTools

## 模块路径
res://core/Scripts/Common/ArrayTools.gd

## 模块功能
数组工具类，提供数组相关的通用工具方法

## 涉及模块
- GameCore: 通过 GameCore.ArrayTools 调用

# 成员变量

无

# 成员方法

- deduplicate(array) -> Array
   - @param array: 需要去重的数组
   - @return Array: 去重后的新数组
   - 功能说明：
      - 移除数组中的重复元素
      - 使用字典记录已出现的元素
      - 返回不包含重复元素的新数组
   - 用例：
      ```gdscript
      var original_array = [1, 2, 2, 3, 3, 3]
      var deduped_array = GameCore.ArrayTools.deduplicate(original_array)
      # 结果：[1, 2, 3]
      ```

# 数据文件

无
