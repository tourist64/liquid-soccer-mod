extends Spatial

var tex = null
var img = null
var msh = null
var shad = null
var meshshad = null
var prev: int
var current: int
var next: int
var col = null
var sim = false
var flip = false
var ball
var balldir
var myGoal
var viewp

func _ready():
	sim = false
	prev = 0
	current = 1
	next = 2
	viewp = $Viewport
func setupData():
	
	
	img.lock()
	
	for i in range(0, msh.nverts):
		img.set_pixel(i, 0, Color(msh.verts[i].x, msh.verts[i].y, msh.verts[i].z, 1))
		img.set_pixel(i, 1, Color(msh.verts[i].x, msh.verts[i].y, msh.verts[i].z, 1))
		img.set_pixel(i, 2, Color(msh.verts[i].x, msh.verts[i].y, msh.verts[i].z, 1))
		img.set_pixel(i, 3, Color(msh.verts[i].x, msh.verts[i].y, msh.verts[i].z, 1))
		
		img.set_pixel(i, 4, Color(msh.normals[i].x, msh.normals[i].y, msh.normals[i].z, 1))
		img.set_pixel(i, 5, Color(msh.pins[i].r, msh.pins[i].g, msh.pins[i].b, 1))
		var vedges = msh.vedges[i].size()
		img.set_pixel(i, 6, Color(vedges, 1, 1, 1))
		for j in range(0, vedges):
			var v = msh.vedges[i][j]
			img.set_pixel(i, j + 10, Color(i, v, msh.dists[i][j], 1.0))
		
			
	
	
func _initialize(mshI):
	shad = $Viewport / SimTex.material
	prev = 0
	current = 1
	next = 2
	
	
	
	img = Image.new()
	img.create(256, 64, false, Image.FORMAT_RGBF)
	msh = mshI
	
	meshshad = mshI.get_surface_material(0)
	msh._processMesh()
	
	
	setupData()
	
	tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	tex.set_storage(ImageTexture.STORAGE_RAW)
	tex.set_data(img)
	
	$Viewport / SrcTex.texture = tex
	
	$TextureRect.texture = $Viewport.get_texture()
	
	
	shad.set("shader_param/frame", 0.0)
	shad.set("shader_param/ball", ball.translation)
	
	var buf = [prev, current, next]
	meshshad.set_shader_param("texture_verts", $Viewport.get_texture())
	meshshad.set_shader_param("gfxSim", true)

	shad.set_shader_param("buffs", buf)
	viewp.render_target_update_mode = 1
	yield(VisualServer, "frame_post_draw")
	
	
	$Viewport / SrcTex.visible = false
func _calcNet():
	
	sim = true
	
func _endNet():
	sim = false
	
func _process(delta):
	if not sim:
		return
	
	var pos = ball.translation
	
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
	
	shad.set("shader_param/frame", delta)
	shad.set("shader_param/ball", pos)
	shad.set("shader_param/ballv", vel)
	var buf = [prev, current, next]
	shad.set_shader_param("buffs", buf)
	meshshad.set_shader_param("framemod", next)
	viewp.render_target_update_mode = 1
	
	prev = current
	current = next
	next = (next + 1) % 3

	
