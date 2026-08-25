extends ImmediateGeometry


export var p1: Vector3
export var p2: Vector3
export var draw: bool
export var drawP: bool
export var thick: float
var delt = 0.0167
var path = []

func _ready():
	clear()
	draw = false
	drawP = false
	path.resize(80)
	
	set_process(false)
	p1 = Vector3(0, 1, 0)
	p2 = Vector3(5, 1, 0)
	thick = 2.0
func _clean():
	clear()
func calcPath( var start, var v, var curl):
	var vert = start
	var vel = v
	for i in range(80):
		path[i] = vert
		vert += vel * delt
		vel += Vector3(0, - 1.2, 0) + curl * delt * 50
	

func process(_delta):
	if draw:
		clear()
		begin(Mesh.PRIMITIVE_LINES)
		
		add_vertex(p1 + Vector3(0, 3, 0))
		add_vertex(p2 + Vector3(0, 3, 0))
		end()
	elif drawP:
		clear()
		begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		add_vertex(path[0] + Vector3(0, 0, - 1))
		add_vertex(path[0] + Vector3(0, 0, 1))
		add_vertex(path[1] + Vector3(0, 0, - 1))
		var off = 1
		for i in range(2, 79):
			add_vertex(path[i] + Vector3(0, 0, off))
			off *= - 1
				
		end()
		
