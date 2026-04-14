## Simplex 噪声实现
## 用于生成程序化地形和不规则形状

class_name SimplexNoise
extends RefCounted

var seed: int
var perm: Array

func _init(seed: int):
	self.seed = seed
	self.perm = []
	for i in range(256):
		self.perm.append(i)
	
	# 使用独立的随机数生成器
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	# 在GDScript中，shuffle不接受参数，我们需要手动打乱
	for i in range(self.perm.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		# 在GDScript中，Array没有swap方法，我们需要手动交换
		var temp = self.perm[i]
		self.perm[i] = self.perm[j]
		self.perm[j] = temp
	self.perm += self.perm

func noise2d(x: float, y: float, scale: float = 0.05) -> float:
	x *= scale
	y *= scale
	
	# 基础 Simplex 噪声实现
	var F2 = 0.5 * (sqrt(3.0) - 1.0)
	var G2 = (3.0 - sqrt(3.0)) / 6.0
	
	var s = (x + y) * F2
	var i = int(floor(x + s))
	var j = int(floor(y + s))
	var t = float(i + j) * G2
	var X0 = float(i) - t
	var Y0 = float(j) - t
	var x0 = x - X0
	var y0 = y - Y0
	
	var i1
	var j1
	if x0 > y0:
		i1 = 1
		j1 = 0
	else:
		i1 = 0
		j1 = 1
	
	var x1 = x0 - float(i1) + G2
	var y1 = y0 - float(j1) + G2
	var x2 = x0 - 1.0 + 2.0 * G2
	var y2 = y0 - 1.0 + 2.0 * G2
	
	i &= 255
	j &= 255
	var n0 = _grad(perm[i + perm[j]], x0, y0)
	var n1 = _grad(perm[i + i1 + perm[j + j1]], x1, y1)
	var n2 = _grad(perm[i + 1 + perm[j + 1]], x2, y2)
	
	return 70.0 * (n0 + n1 + n2)

func _grad(hash_val: int, x: float, y: float) -> float:
	var h = hash_val & 7
	var u = y if h < 4 else x
	var v = x if h < 4 else y
	return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)