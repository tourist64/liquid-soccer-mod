extends Camera





var target = null
export var movingcam = true
var last = Vector3.ZERO

func _ready():
	pass
	set_physics_process(false)
func _pickCamera():
	set_physics_process(true)
	current = true
func _endCamera():
	set_physics_process(false)
	current = false
func _setTarget(tar):
	target = tar
	last = tar.translation

func _physics_process(_delta):
	
	if current and target and movingcam:
		last = last * 0.95 + target.translation * 0.05
		
		look_at(last, Vector3.UP)
		
