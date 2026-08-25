extends ImmediateGeometry


export var p1: Vector3
export var p2: Vector3
export var draw: bool = false
export var drawP: bool = false
export var thick: float = 4.0
var delt = 0.0167
var path = []
var offset = Vector3(0, 0, 1)

func _ready():
	clear()
	
	
	path.resize(80)
	
	set_process(false)
	
	
	
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
		begin(Mesh.PRIMITIVE_LINE_STRIP)
		
		add_vertex(p1)
		add_vertex(p2)
		end()
	elif drawP:
		clear()
		begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		add_vertex(path[0] - offset)
		add_vertex(path[0] + offset)
		add_vertex(path[1] - offset)
		
		for i in range(2, 79, 2):
			add_vertex(path[i] + offset)
			add_vertex(path[i + 1] - offset)
			
			
				
		end()
		
