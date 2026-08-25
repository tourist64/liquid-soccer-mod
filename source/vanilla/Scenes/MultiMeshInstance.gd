extends MultiMeshInstance








func _ready():
	var z = Vector3( - 0.02, 0, 0)
	var y = Vector3(0, 0.02, 0)
	var x = Vector3(0, 0, 0.02)
	
	for i in range(0, multimesh.instance_count):
		var t = multimesh.get_instance_transform(i)
		var pos = t.origin
		multimesh.set_instance_transform(i, Transform(Basis(x, y, z), pos))
		





