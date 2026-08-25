extends MeshInstance
var verts: PoolVector3Array
var normals: PoolVector3Array
var nverts = 0
var vedges = []
var dists = []


var pins: PoolColorArray



func _ready():
	pass

func _processMesh():
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	nverts = mdt.get_vertex_count()
		
		
	for i in range(nverts):
		verts.append(mdt.get_vertex(i))
		normals.append(mdt.get_vertex_normal(i))
		
		dists.append([])
		vedges.append([])
		
		pins.append(mdt.get_vertex_color(i))
		if (i == 18) or (i == 46) or (i == 76):
			pins[i] = Color.white
			
	
	for i in range(mdt.get_edge_count()):
		var e1 = mdt.get_edge_vertex(i, 0)
		var e2 = mdt.get_edge_vertex(i, 1)
		vedges[e1].append(e2)
		vedges[e2].append(e1)
		var diff = verts[e1] - verts[e2]
		dists[e1].append(diff.length())
		dists[e2].append(diff.length())
		
	
	
	for i in range(nverts):
		
		pins[i].g = float(i) / 163.0
		mdt.set_vertex_color(i, pins[i])
	
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)

