
#  基础规则
# 0.1. 基础规则
    禁止在函数内部创建函数
    禁止使用多行注释"""，"""注释内容"""，使用#注释
    函数注解、模块注解使用##
# 0.2. 基础代码调用用例
    数组去重
        new_array = GameCore.ArrayTools.deduplicate(array)
    字典合并
        new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
    时间获取
        time_string =  Time.get_datetime_string_from_system()
    调用其他模块
        result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
# 1. 代码注释
# 1.1. 为文件适当添加注释
    给出配置
    给出输入输出的数据结构
    说明模块的功能
    给出模块的用例
    给出涉及模块的名称
# 1.2. 在文件头给出模块的主要功能以及对应方法
# 1.3. 给出功能的用例
# 2. 模块交互
    通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
        不需要判断 Engine.has_meta(mod_name)
        因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。
#  基础逻辑/基础功能
##  声明全局种子，GameCore.Settings.GameSettings.WorldSeed，所有方法的随机数都基于这个种子，每个步骤的随机数都基于全局种子，确保可重复生成相同结果。
##  基础代码内容：
    ...
##  提供功能
#  成员变量
#  成员方法
#  数据文件
