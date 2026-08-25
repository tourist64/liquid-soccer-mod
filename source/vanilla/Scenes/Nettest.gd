extends MeshInstance

var mdt
var frame = 1
var pins: PoolVector3Array
var lverts: PoolVector3Array
var verts: PoolVector3Array
var tverts: PoolVector3Array
var overts: PoolVector3Array

var norms: PoolVector3Array
var edges: PoolIntArray
var vedges = []
var dists = []
var nverts
var hasdata = false
var flip = false
var ball
var balldir
var myGoal
var timemult = 1
var sim = false
var dd = 0.016667

const ddnormal = 0.01

const ddreplay = 0.005
export var cvel: Vector3

func _ready():
	set_process(false)
func _initialize():
	mdt = MeshDataTool.new()
	
	
	balldir = Vector3.ZERO
	mdt.create_from_surface(mesh, 0)
	nverts = mdt.get_vertex_count()
	
	
	for i in range(nverts):
		verts.append(mdt.get_vertex(i))
		tverts.append(verts[i])
		overts.append(verts[i])
		
		norms.append(mdt.get_vertex_normal(i))
		vedges.append([])
		
		dists.append([])
		pins.append(Vector3(mdt.get_vertex_color(i).r, 0.0, 0.0))
		if (i == 18) or (i == 46) or (i == 76):
			pins[i] = Vector3.ONE
	
	for i in range(mdt.get_edge_count()):
		var e1 = mdt.get_edge_vertex(i, 0)
		var e2 = mdt.get_edge_vertex(i, 1)
		vedges[e1].append(e2)
		vedges[e2].append(e1)
		var diff = verts[e1] - verts[e2]
		dists[e1].append(diff.length())
		dists[e2].append(diff.length())
	
	
	
	
		
	sim = false
	lverts = verts
	hasdata = true
	
	
func _isReplay():
	dd = ddreplay
func _isNormal():
	dd = ddnormal
	

func _calcNet():
	sim = true
	set_process(true)
func _endNet():
	
	sim = false
	set_process(false)
	
	mdt.create_from_surface(mesh, 0)
	
	for i in range(nverts):
		mdt.set_vertex(i, overts[i])
		
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	
func _process(delta):
	
	
	
	var bmult = 1.0
	var pos = ball.translation + ball.linear_velocity * delta
	
	if abs(pos.x) > 150.0 or abs(pos.z) > 30.0:
		bmult = 0.0
	var ymult = Vector3(1.0, 0.33, 1.0)
	var dir = ball.linear_velocity
	var vel = dir.length()
	
		
	if ( not flip):
		pos = to_global(pos)
		pos.y *= 0.809
		pos.z *= 0.809
	
	else:
		pos = pos - myGoal
		pos.y *= 0.909
		pos.z *= 0.909
	
	
	var dball = Vector3.ZERO
	var last = dball
	var bmul = 0.0
	
	
	mdt.create_from_surface(mesh, 0)
	
	for i in range(nverts):
			
		var force = Vector3.ZERO
		var forces = Vector3(0, - 20.0 * dd, 0)
		for j in range(vedges[i].size()):
			var v = vedges[i][j]
			
			var sv = verts[i] - verts[v]
			
			var nl = dists[i][j]
			var dv = sv.length()
			var fs = 1.0 - (nl / dv)
			force += ( - sv * fs) * pins[i].x * 2.0





			
		
		force += (overts[i] - verts[i]) * 0.15
		
		dball = (verts[i] - pos)
		
		
		forces += force * 8 * 0.95;
		
		var D = verts[i].length()
		
		forces += (1.0 - smoothstep(3.0, 3.5, dball.length())) * norms[i] * 5.0 * bmult
		
		bmul = 1.0 - smoothstep(11, 12, abs(pos.y))
		bmul *= 1.0 - smoothstep(0.0, 18.0, abs(pos.z))
		if norms[i].dot(pos) - D > 0 and pos.x < 0:
			forces += 8.0 * norms[i] * bmul
		forces += (1.0 - smoothstep(3.0, 3.5, dball.length())) * norms[i] * (1.0 + vel * 0.5) * pins[i].x * ymult
		
		
		last = (verts[i] - lverts[i]) * 0.95
		tverts[i] = verts[i] + last + forces * dd * pins[i].x
		
		mdt.set_vertex(i, tverts[i])
	
	
		
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	lverts = verts
	verts = tverts
	frame += 1
