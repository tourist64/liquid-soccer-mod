extends Spatial
var mat = null
var amat = null
var pmat = null
var adsmat = null
var crowd = false
var away = false
var bmat = null
var bmat2 = null
var doInit = false



var fc = 0
var ad = 0
var cad = 0
var mdt = null
var validFaces = []
var positions = []
var bowl = null

func _ready():
	
	pmat = $SmallStadium / Pitch1.get_surface_material(0)
	adsmat = $SmallStadium / Decoration / adsg1 / big_ads.get_surface_material(0)
	bmat2 = $SmallStadium / Decoration / Banner1.get_active_material(0)
	bmat = $SmallStadium / Decoration / Banner2.get_active_material(0)
	bmat.set_shader_param("team1", Global.t2.Shirt1Color)
	bmat.set_shader_param("team2", Global.t2.Shirt2Color)
	bmat.set_shader_param("team3", Global.t2.numberColor)
	bmat2.set_shader_param("team1", Global.t1.Shirt1Color)
	bmat2.set_shader_param("team2", Global.t1.Shirt2Color)
	bmat2.set_shader_param("team3", Global.t1.numberColor)
func _physics_process(delta):
	fc += 1
	
	
	
		
	
	
	if fc > 240:
		adsmat.set_shader_param("id", cad + ad)
		ad += delta
		if (ad > 1):
			ad = 0
			cad = fmod(cad + 1, 8)
			fc = 0
			
func processMesh( var mesh, var fans):
	mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	positions.clear()
	validFaces.clear()
	
	for i in range(mdt.get_face_count()):
		var n = mdt.get_face_normal(i)
		if n.y > 0.4:
			validFaces.append(i)
	
	
	var tf = validFaces.size()
	for _i in range(fans):
		
		var f = int(rand_range(0, tf))
		
		var v1 = mdt.get_face_vertex(validFaces[f], 0)
		var v2 = mdt.get_face_vertex(validFaces[f], 1)
		var v3 = mdt.get_face_vertex(validFaces[f], 2)
		var A = mdt.get_vertex(v1)
		var B = mdt.get_vertex(v2)
		var C = mdt.get_vertex(v3)
		
		
		var r1 = rand_range(0, 1)
		var r2 = rand_range(0, 1)
		
		var P = (1.0 - sqrt(r1)) * A + (sqrt(r1) * (1.0 - r2)) * B + (sqrt(r1) * r2) * C
		
		
		positions.append(P * 100)
		
func _initStand(mm, fans, _lookat, mesh):
	
	
	if away:
		amat.set_shader_param("Shirt2", Global.t2.Shirt1Color)
	else:
		mat.set_shader_param("Shirt2", Global.t1.Shirt1Color)
	var ic = mm.instance_count

	
	processMesh(mesh, fans)
	
	
	for i in range(0, ic):
	
		var t = Transform(Basis(), Vector3.ZERO)
		
		t = t.translated(positions[i])
		
		
		t = t.looking_at(positions[i] * 2.0, Vector3.UP)
		t = t.scaled(Vector3(0.01, 0.01, 0.01))
		
		
		mm.set_instance_transform(i, t)
		mm.set_instance_custom_data(i, Color(randf(), randf(), randf(), randf()))

func _initStandOld(m, start, xadd, yadd, zadd, lookat, orient, seats):
	mat = m.mesh.surface_get_material(0)
	mat.set_shader_param("doAnim", 1)
	if away:
		amat.set_shader_param("Shirt", Global.t2.Shirt1Color)
		amat.set_shader_param("Shirt2", Global.t2.Shirt2Color)
	else:
		mat.set_shader_param("Shirt2", Global.t1.Shirt1Color)
		mat.set_shader_param("Shirt", Global.t2.Shirt2Color)
	var ic = m.instance_count
	var pos
	var arr = []
	for i in range(12 * seats):
		arr.append(i)
	arr.shuffle()
	
	for i in range(0, ic):
		var seat = floor(arr[i])
		var row = floor(seat / seats)
		seat = fmod(seat, seats)
		
		if (orient == 0):
			pos = start + Vector3(seat * xadd, row * yadd, row * zadd)
			pos.x += rand_range( - 1.0, 1.0)
		else:
			pos = start + Vector3(row * xadd, row * yadd, seat * zadd)
			pos.z += rand_range( - 1.0, 1.0)
		var t = Transform(Basis(), Vector3.ZERO)
		
		
		
		t = t.translated(pos)
		t = t.looking_at(lookat, Vector3.UP)
		m.set_instance_transform(i, t)
		m.set_instance_custom_data(i, Color(randf(), randf(), randf(), randf()))
		
		


func _initBowlCrowd():
	amat = $MultiMeshInstance.material_override
	mat = $MultiMeshInstance7.multimesh.mesh.surface_get_material(0)
	amat.set_shader_param("Shirt2", Global.t2.Shirt1Color)
	mat.set_shader_param("Shirt2", Global.t1.Shirt1Color)
	for c in get_children():
		if c is MultiMeshInstance and c != $MultiMeshInstance and c != $MultiMeshInstance7:
			c.visible = false
	if bowl.paintText:
		# Tifo: fans on the letters wear the home shirt (Shirt2), the ones around them navy (Shirt).
		mat.set_shader_param("Shirt", bowl.tifoBg)
	_fillCrowd($MultiMeshInstance7, bowl.seats(int(4800 * bowl.crowdScale), false), bowl.lastTifo)
	_fillCrowd($MultiMeshInstance, bowl.seats(int(700 * bowl.crowdScale), true))
	var nearFans = $MultiMeshInstance7.duplicate()
	nearFans.name = "NearUpperFans"
	nearFans.multimesh = $MultiMeshInstance7.multimesh.duplicate()
	nearFans.visible = false
	add_child(nearFans)
	_fillCrowd(nearFans, bowl.seats(int(1400 * bowl.crowdScale), false, true), bowl.lastTifo)
	bowl.nearCrowd = nearFans
	crowd = true

func _fillCrowd(mmi, pts, tifo = null):
	var mm = mmi.multimesh
	mm.instance_count = pts.size()
	var inv = mmi.global_transform.affine_inverse()
	for i in range(pts.size()):
		var l = inv.xform(pts[i])
		var t = Transform(Basis(), l).looking_at(l + Vector3(l.x, 0.0, l.z), Vector3.UP)
		t.basis = t.basis.scaled(Vector3(0.0075, 0.0075, 0.0075))
		mm.set_instance_transform(i, t)
		var data = Color(randf(), randf(), randf(), randf())
		# Tifo fans: g picks the shirt (0 = Shirt, 1 = Shirt2); b and a stay low so no other shirt shows.
		if tifo != null and i < tifo.size() and tifo[i] > 0:
			data = Color(randf(), 1.0 if tifo[i] == 2 else 0.0, randf() * 0.55, randf() * 0.75)
		mm.set_instance_custom_data(i, data)

func _initCrowd():
	if bowl:
		_initBowlCrowd()
		return
	
	
	
	
	
	
	amat = $MultiMeshInstance.material_override
	
	away = true
	var mm = $MultiMeshInstance.multimesh
	mm.instance_count = 200
	var mesh = $SmallStadium / Decoration / Stand12 / Stand4_ncl1_2.mesh
	
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	away = false
	mm = $MultiMeshInstance7.multimesh
	mat = mm.mesh.surface_get_material(0)
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / Stand / Stand1.mesh
	
	_initStand(mm, 200, Vector3.ZERO, mesh)
	mm = $MultiMeshInstance2.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / Stand / Stand2.mesh
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance8.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / EndStand1 / Stand5.mesh
	
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance3.multimesh
	mm.instance_count = 300
	mesh = $SmallStadium / Decoration / Stand12 / Stand3_ncl1_2.mesh
	_initStand(mm, 300, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance9.multimesh
	mm.instance_count = 300
	mesh = $SmallStadium / Decoration / EndStand / Stand7.mesh
	_initStand(mm, 300, Vector3.ZERO, mesh)
	
	
	mm = $MultiMeshInstance4.multimesh
	mm.instance_count = 300
	mesh = $SmallStadium / Decoration / EndStand / Stand8.mesh
	_initStand(mm, 300, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance10.multimesh
	mm.instance_count = 300
	mesh = $SmallStadium / Decoration / EndStand / Stand10.mesh
	_initStand(mm, 300, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance5.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / EndStand / Stand11.mesh
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance11.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / Stand1_ncl1_1 / Stand3.mesh
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance6.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / Stand1_ncl1_1 / Stand4.mesh
	
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance12.multimesh
	mm.instance_count = 300
	mesh = $SmallStadium / Decoration / EndStand2 / EndStand2_Stand6.mesh
	_initStand(mm, 300, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance13.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / Stand9 / Stand3_ncl1_1.mesh
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance14.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / Stand9 / Stand4_ncl1_1.mesh
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	mm = $MultiMeshInstance15.multimesh
	mm.instance_count = 200
	mesh = $SmallStadium / Decoration / EndStand1 / Stand6.mesh
	_initStand(mm, 200, Vector3.ZERO, mesh)
	
	
	crowd = true
func _celebrate():
	if (crowd):
		mat.set_shader_param("doAnim", 1)
		mat.set_shader_param("startframe", 241)
		mat.set_shader_param("framerange", 120.0)
func _awayCelebrate():
	if (crowd):
		amat.set_shader_param("doAnim", 1)
		amat.set_shader_param("startframe", 241)
		amat.set_shader_param("framerange", 120.0)
	
func _relax():
	if (crowd):
		mat.set_shader_param("startframe", 1)
		mat.set_shader_param("framerange", 120.0)
		amat.set_shader_param("startframe", 1)
		amat.set_shader_param("framerange", 120.0)
	
	
func _conceded():
	if (crowd):
		mat.set_shader_param("startframe", 121)
		mat.set_shader_param("framerange", 120.0)
func _awayConceded():
	if (crowd):
		amat.set_shader_param("startframe", 121)
		amat.set_shader_param("framerange", 120.0)
func _applause():
	if (crowd):
		mat.set_shader_param("startframe", 31.0)
		mat.set_shader_param("framerange", 30.0)
func _setShadows():
	var shads = Global.config.get_value("gfx", "doshadows")
	$DirectionalLight.shadow_enabled = shads
	
