extends RefCounted
class_name _DictionaryTools

## 深度合并两个字典
## @param dict1 目标字典
## @param dict2 源字典，将合并到 dict1 中
## @return 合并后的字典
func merge(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	# 创建 dict1 的副本，避免修改原始字典
	var result = dict1.duplicate(true)
	
	# 遍历 dict2 中的所有键值对
	for key in dict2.keys():
		var value2 = dict2[key]
		
		# 如果 dict1 中存在相同的键
		if result.has(key):
			var value1 = result[key]
			
			# 如果两个值都是字典，则递归合并
			if value1 is Dictionary and value2 is Dictionary:
				result[key] = merge(value1, value2)
			# 否则，使用 dict2 中的值覆盖 dict1 中的值
			else:
				result[key] = value2
		# 如果 dict1 中不存在该键，则直接添加
		else:
			result[key] = value2
	
	return result

## 测试 merge 函数的功能
func test_merge():
	# 测试数据 1
	var dict1 = {
		"a": 1,
		"b": {
			"c": 2,
			"d": 3
		},
		"e": [1, 2, 3]
	}
	
	# 测试数据 2
	var dict2 = {
		"a": 10,
		"b": {
			"c": 20,
			"f": 4
		},
		"g": 5
	}
	
	# 执行合并
	var merged = merge(dict1, dict2)
	
	# 打印结果
	print("测试数据 1:")
	print(dict1)
	print("测试数据 2:")
	print(dict2)
	print("合并结果:")
	print(merged)
	
	# 验证结果
	assert(merged["a"] == 10, "a 应该被覆盖为 10")
	assert(merged["b"]["c"] == 20, "b.c 应该被覆盖为 20")
	assert(merged["b"]["d"] == 3, "b.d 应该保持为 3")
	assert(merged["b"]["f"] == 4, "b.f 应该被添加为 4")
	assert(merged["e"] == [1, 2, 3], "e 应该保持不变")
	assert(merged["g"] == 5, "g 应该被添加为 5")
	
	print("所有测试通过!")

func deduplicate(dict):
	pass
	
