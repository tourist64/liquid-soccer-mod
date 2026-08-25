extends Control






var game = null
var hud = null
var vptex = null
var cframe = 0
var frame = 0

func _ready():
	$TextureRect / OptionButton.add_item("Main")
	$TextureRect / OptionButton.add_item("replay 1")
	$TextureRect / OptionButton.add_item("replay 2")
	$TextureRect / OptionButton.add_item("replay 3")
	set_process(false)
func _initWindow():
	$TextureRect / OptionButton.select(game.currCam)
	
func _setTexture( var tex):
	$TextureRect / ViewportContainer / Viewport / TR.texture = tex
	hud = get_parent()
	vptex = tex

func saveImage():
	var img = vptex.get_data()
	
	img.flip_y()
	var strin = "user://vids/test%04d.png" % frame
	img.save_png(strin)
	
	

func _process(_delta):
	cframe = (cframe + 1) % 6
	
	if cframe == 0:
		saveImage()
		frame += 1
	if frame > 99:
		set_process(false)
		game._renderFinish()
		print("done capturing")
		makeVideo()

func makeVideo():
	var ddir = OS.get_user_data_dir()
	print(ddir)
	var ppath = ProjectSettings.globalize_path("res://ffmpeg")
	print(ppath)
	
	var cmd = ddir + "/vids/test%04d.png"
	var vid = ddir + "/vids/goal.mp4"
	var output = []
	print(cmd)
	
	var _res = OS.execute(ppath, ["-r", "10", "-i", cmd, "-vcodec", "libx264", "-pix_fmt", "yuv420p", "-crf", "25", vid], true, output)
	
	print(output)
	
	
func _on_OptionButton_item_selected(index):
	print("change camera")
	game._switchCamera(index)
	

func _on_ButtonCancel_pressed():
	visible = false
	hud._on_ButtonResume_pressed()
	

func _on_ButtonCapture_pressed():
	var dir = Directory.new()
	dir.make_dir("user://vids")
	game._renderVid()
	set_process(true)
	get_tree().paused = false
