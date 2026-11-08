extends Camera

class_name InterpolatedCamera3D



export var translate_min: = 1
export var translate_max: = 15

var target_node = null
var game = null


export var target: NodePath
var shake = 0
var targetfov = 40
var limitX = 100
var limitZ = 65
export var mlimitx = 120
export var mlimitz = 65
export var mfov = 45
export var zoffset = 70
export var xoffset = 0
func _ready():
	
	target_node = get_node(target) as Spatial
	_setLimits()
	set_process(false)
	set_physics_process(false)
	
	_setupCamera()
	

func _setupCamera():
	
	match Global.config.get_value("gfx", "camtype"):
		0:
			zoffset = Global.config.get_value("gfx", "camoffset")
			xoffset = 0
			mfov = Global.config.get_value("gfx", "camfov")
			fov = mfov
			rotation_degrees.x = Global.config.get_value("gfx", "camtilt")
			translation.y = Global.config.get_value("gfx", "camheight")
		1:
			xoffset = Global.config.get_value("gfx", "camUDoffset")
			zoffset = 0
			mfov = Global.config.get_value("gfx", "camUDfov")
			fov = mfov
			rotation_degrees.x = Global.config.get_value("gfx", "camUDtilt")
			translation.y = Global.config.get_value("gfx", "camUDheight")
		2:
			xoffset = 0
			zoffset = Global.config.get_value("gfx", "camLRoffset")
			mfov = Global.config.get_value("gfx", "camLRfov")
			fov = mfov
			rotation_degrees.x = Global.config.get_value("gfx", "camLRtilt")
			translation.y = Global.config.get_value("gfx", "camLRheight")
	if Global.elevenMode:
		_setupElevenCamera()
	targetfov = mfov

func _setTarget( var t):
	target_node = t as Spatial
	
func _setGame( var g):
	game = g
	set_process(true)
	mfov = fov
func _setCelebrate():
	limitX = min(limitX + 50, 150 * Global.ps)
	limitZ = min(limitZ + 40, 85 * Global.ps)
	
	targetfov = 28
	
func _setLimits():
	limitX = mlimitx * Global.ps
	limitZ = mlimitz * Global.ps
	fov = mfov
	targetfov = mfov
	
func _process(delta: float) -> void :
	
	
	if target == null:
		return
	if _isElevenView():
		_elevenStep(delta)
		if fov != targetfov:
			fov -= (fov - targetfov) * delta * 2.0
		shake *= 0.95
		return
	var lpos = target_node.translation + Global.ballvel * delta * 4.0
	
	var nx = xoffset + min(max( - limitX, lpos.x), limitX) + (shake * (rand_range( - 6, 6)) * delta)
	var nz = zoffset + min(max( - limitZ, lpos.z), limitZ) + (shake * (rand_range( - 6, 6)) * delta)
	var updatedt = Vector3(nx, translation.y, nz)
	var updated = updatedt - translation
	var speed = 1.0
	if updated.length_squared() > 1.0:
		speed = lerp(0.1, 5, smoothstep(4, 10, updated.length()))
	
	translation = translation.linear_interpolate(updatedt, delta * speed)
	if fov != targetfov:
		fov -= (fov - targetfov) * delta * 2.0
	shake *= 0.95


func _updateCam( var delta):
	if _isElevenView():
		_elevenStep(delta)
		return
	var lpos = target_node.translation + Global.ballvel * delta * 4.0
	
	var nx = xoffset + min(max( - limitX, lpos.x), limitX) + (shake * (rand_range( - 6, 6)) * delta)
	var nz = zoffset + min(max( - limitZ, lpos.z), limitZ) + (shake * (rand_range( - 6, 6)) * delta)
	var updatedt = Vector3(nx, translation.y, nz)
	var updated = updatedt - translation
	var speed = 1.0
	if updated.length_squared() > 1.0:
		speed = lerp(0.1, 5, smoothstep(4, 10, updated.length()))
	
	translation = translation.linear_interpolate(updatedt, delta * speed)
	
		
func set_target_node(node):
	target_node = node as Spatial

# --- 11v11 cameras --------------------------------------------------------------------
# Two sideline views, chosen in the pause menu's camera list (gfx/elevenview):
#   0 tele broadcast: stays near the halfway line up in the stands and pans to follow play.
#   1 co-op: higher and square to the pitch, tracks along the touchline without panning.
# The settings sliders offset each view by how far they are from their defaults.
const CAM_DEFAULTS = {"camoffset": 70.0, "camheight": 75.0, "camtilt": - 48.0, "camfov": 45.0}
const VIEW_BROADCAST = 0
const VIEW_COOP = 1
const ELEVEN_FOV = 27.0
const GOAL_LINE_X = 173.0
const COOP_LIMIT_X = 105.0

var elevenLook = Vector3.ZERO
var elevenTilt = 0.0

func _isElevenView():
	return Global.elevenMode and self == _mainElevenCamera()

func _mainElevenCamera():
	return get_parent().get_node_or_null("Camera")

func _elevenView():
	return int(Global.config.get_value("gfx", "elevenview", VIEW_BROADCAST))

func _camDelta(key):
	var v = Global.config.get_value("gfx", key, CAM_DEFAULTS[key])
	return float(v) - CAM_DEFAULTS[key]

func _setupElevenCamera():
	if not _isElevenView():
		translation.y *= Global.ps
		xoffset *= Global.ps
		zoffset *= Global.ps
		return
	far = max(far, 1500.0)
	near = 1.0
	xoffset = 0
	var back = _camDelta("camoffset") * Global.ps
	var height = _camDelta("camheight") * Global.ps
	mfov = clamp(ELEVEN_FOV + _camDelta("camfov") * 0.5, 14.0, 55.0)
	fov = mfov
	targetfov = mfov
	elevenLook = Vector3.ZERO
	if _elevenView() == VIEW_COOP:
		var coopTilt = deg2rad(26.0)
		zoffset = 215.0 + back * cos(coopTilt)
		translation.y = max(30.0, 105.0 + back * sin(coopTilt) + height)
		elevenTilt = clamp( - 26.0 + _camDelta("camtilt"), - 80.0, - 10.0)
		rotation_degrees = Vector3(elevenTilt, 0.0, 0.0)
	else:
		var broadcastTilt = deg2rad(20.0)
		zoffset = 207.0 + back * cos(broadcastTilt)
		translation.y = max(30.0, 75.0 + back * sin(broadcastTilt) + height)
		elevenTilt = clamp(_camDelta("camtilt"), - 40.0, 40.0)
	translation.x = 0.0
	translation.z = zoffset

func _elevenStep(delta):
	var lpos = target_node.translation + Global.ballvel * delta * 4.0
	var bx = clamp(lpos.x, - GOAL_LINE_X, GOAL_LINE_X)
	var bz = clamp(lpos.z, - 112.0, 112.0)
	var jitter = shake * rand_range( - 6, 6) * delta
	var goal
	if _elevenView() == VIEW_COOP:
		goal = Vector3(clamp(bx, - COOP_LIMIT_X, COOP_LIMIT_X) + jitter, translation.y, zoffset + bz * 0.5)
	else:
		goal = Vector3(bx * 0.15 + jitter, translation.y, zoffset)
	var dist = (goal - translation).length()
	var speed = 1.0
	if dist * dist > 1.0:
		speed = lerp(0.1, 5, smoothstep(4, 10, dist))
	translation = translation.linear_interpolate(goal, min(1.0, delta * max(speed, 2.0)))
	if _elevenView() == VIEW_BROADCAST:
		var want = Vector3(bx * 0.85, 0.0, bz * 0.55)
		elevenLook = elevenLook.linear_interpolate(want, min(1.0, delta * 3.0))
		look_at(elevenLook, Vector3.UP)
		rotate_object_local(Vector3.RIGHT, deg2rad(elevenTilt))
