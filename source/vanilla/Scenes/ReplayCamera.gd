extends Camera





var target = null
export var movingcam = true


func _ready():
	pass
func _setTarget(tar):
	target = tar


func _physics_process(_delta):
	if current and target and movingcam:
		look_at(target.translation, Vector3.UP)
