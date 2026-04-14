extends RefCounted
class_name _BaseTools


func pos_str_to_veci(str:String) -> Vector2i:
	var str_arr = str.split(",")
	return Vector2i(int(str_arr[0]), int(str_arr[1]))

func veci_to_pos_str(vec:Vector2i) -> String:
	return "%d,%d" % [vec.x, vec.y]
