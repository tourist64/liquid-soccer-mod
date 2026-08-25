extends ImmediateGeometry






export var width: float = 0.5
export var width_curve: Curve

export var max_points: = 100
export var material: Material

export var render: bool = false
var ball
export var face = 0
var node
var rend
var st



onready var half_width = width * 0.5
var points: = []






func _ready() -> void :
	node = Node.new()
	add_child(node)
	
	
	
	global_transform = Transform()
	set_process(false)
func process(_delta: float) -> void :
	if not Global.doTrail:
		return
	if render:
		
		add_point()
		_draw_trail()
	else:
		
		if points.size() > 0:
			var _last_point = points.pop_back()
			_draw_trail()
		
			
		

func _clear():
	
	points.clear()



func add_point() -> void :
	
	
	
	
	var new_point = ball.translation
	points.insert(0, new_point)
	if points.size() > max_points:
		var _last_point = points.pop_back()
		


func _draw_trail() -> void :
	if points.size() < 1:
		return
	
	
	
	
	
	clear()
	begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, null)
	
	for i in range(points.size() - 1):
		_points_to_rect(points[i], points[i + 1], i)
	end()
	
	
	


func _points_to_rect(p1: Vector3, p2: Vector3, idx: float) -> void :
	var num_points = points.size() - 1
	var off = Vector3(0, 0.5, 0);
	var offup = Vector3(0, 1, 1);
	
	if (face):
		off = offup
	var offset1 = idx / num_points
	
	
	var v1 = p1 + off
	var uv1 = Vector2(0, offset1)
	
	var v2 = p1 - off
	var uv2 = Vector2(1, offset1)
	
	var offset2 = (idx + 1) / num_points
	
	var v3 = p2 + off
	var uv3 = Vector2(0, offset2)
	
	var v4 = p2 - off
	var uv4 = Vector2(1, offset2)
	
	set_uv(uv1)
	add_vertex(v1)
	set_uv(uv2)
	add_vertex(v2)
	set_uv(uv3)
	add_vertex(v3)
	
	set_uv(uv3)
	add_vertex(v3)
	set_uv(uv2)
	add_vertex(v2)
	set_uv(uv1)
	add_vertex(v1)
	
	set_uv(uv3)
	add_vertex(v3)
	set_uv(uv4)
	add_vertex(v4)
	set_uv(uv2)
	add_vertex(v2)
	
	
	
	
	
	
	
