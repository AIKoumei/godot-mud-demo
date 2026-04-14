# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 字典深度合并
   ```gdscript
   new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
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
DictionaryTools

## 模块路径
res://core/Scripts/Common/DictionaryTools.gd

## 模块功能
字典工具类，提供字典相关的通用工具方法

## 涉及模块
- GameCore: 通过 GameCore.DictionaryTools 调用

# 成员变量

无

# 成员方法

- merge(dict1: Dictionary, dict2: Dictionary) -> Dictionary
   - @param dict1: 目标字典
   - @param dict2: 源字典，将合并到 dict1 中
   - @return Dictionary: 合并后的字典
   - 功能说明：
      - 深度合并两个字典
      - 如果键相同且值都是字典，则递归合并
      - 否则使用 dict2 的值覆盖 dict1
      - 返回新字典，不修改原始字典
   - 用例：
      ```gdscript
      var dict1 = {"a": 1, "b": {"c": 2}}
      var dict2 = {"a": 10, "b": {"d": 3}}
      var merged = GameCore.DictionaryTools.merge(dict1, dict2)
      # 结果：{"a": 10, "b": {"c": 2, "d": 3}}
      ```

- test_merge() -> void
   - @return void
   - 功能说明：
      - 测试 merge 函数的功能
      - 验证合并结果是否正确

- deduplicate(dict) -> void
   - @param dict: 需要去重的字典
   - @return void
   - 功能说明：
      - TODO: 未实现
      - 计划用于字典去重

# 数据文件

无
