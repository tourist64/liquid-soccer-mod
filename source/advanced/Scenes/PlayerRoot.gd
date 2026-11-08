extends Spatial

var cam
var label
var rPos: PoolVector3Array
var rVel: PoolVector3Array
var rView: PoolVector3Array
var rState: PoolStringArray
var vptex = null
var game
var myPlayer
var myTeam
var teamID = 0
signal hudpos(teamid, id, pos)
var id
var mat = null
func setColors(shirt, shirt2, shirt3, shorts, skin, number, kit, haircol, hairt, beard):
	id = $Player.myID
	myPlayer = $Player
	mat = $Player / PlayerMesh / QuickRigCharacter_Reference / PlayerM.get_surface_material(0)
	if (kit > 0):
		mat.set_shader_param("kit", kit)
	
	mat.set_shader_param("Shirt", shirt)
	mat.set_shader_param("Shorts", shorts)
	mat.set_shader_param("Skin", skin)
	mat.set_shader_param("Shirt2", shirt2)
	mat.set_shader_param("Shirt3", shirt3)
	mat.set_shader_param("Numbers", number)

	
	if id > 3:
		mat.set_shader_param("numUVOff", 0.445)
	var mult = Vector3(1, 0, 0)
	if (id == 2) or (id == 5):
		mult = Vector3(0, 1, 0)
	elif (id == 3) or (id == 6):
		mult = Vector3(0, 0, 1)
	
	

	mat.set_shader_param("numChannelMult", mult)
	mat.set_shader_param("texture_albedo", Global.t1tex)
	mat.set_shader_param("texture_albedo2", Global.t2tex)
	mat.set_shader_param("texture_albedo_trim", Global.t1trim)
	mat.set_shader_param("texture_albedo2_trim", Global.t2trim)

	if id > Global.squad - 1:
		mat.set_shader_param("doBibs", true)
	
	
	var fh = null
	if Global.xmas:
		$Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / Hat.visible = true
	if beard == 3:
		fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh3
	elif beard == 2:
		fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh2
	elif beard == 1:
		fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / FacialHairMesh
	if fh:
		fh.visible = true
		var fhmat = fh.get_surface_material(0)
		fhmat.set_shader_param("albedo_color", haircol)
	
	fh = null
	
	if Global.setupWomens:
		fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HairBase
		var fhmat = fh.get_surface_material(0)
		fhmat.set_shader_param("albedo_color", haircol)
	match hairt:
		1:
			fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / Hair1
		2:
			fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / Hair2
		3:
			fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / Hair3
		4:
			fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / Hair4
		5:
			fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / Hair5
		6:
			fh = $Player / PlayerMesh / QuickRigCharacter_Reference / HeadAttach / Hair6
			
	
	if fh:
		fh.visible = true
		var fhmat = fh.get_surface_material(0)
		fhmat.set_shader_param("albedo_color", haircol)
	if myTeam == 1:
		$Player / Indicator.get_surface_material(0).albedo_color = Color(0.2, 0.0, 0.9, 1.0)
		$PosInd.get_surface_material(0).set_shader_param("albedo_color", Color(0.2, 0.0, 0.9, 1.0))
		mat.set_shader_param("albedo_color", Color(0.3, 0.85, 0.1))
	else:
		$Player / Indicator.get_surface_material(0).albedo_color = Color(0.9, 0.0, 0.2, 1.0)
		$PosInd.get_surface_material(0).set_shader_param("albedo_color", Color(0.9, 0.0, 0.2, 1.0))
		mat.set_shader_param("albedo_color", Color(0.8, 0.1, 0.8))
	
	
	cam = get_node("/root").get_viewport().get_camera()
	if Global.camrot:
		myPlayer.cud = 0
		myPlayer.clr = 1
		myPlayer.jflip = - 1
	else:
		myPlayer.cud = 1
		myPlayer.clr = 0

func _ready():
	
	
	rPos.resize(360)
	rVel.resize(360)
	rView.resize(360)
	rState.resize(360)
	myPlayer = get_child(0)
	
	for i in range(0, 360):
		rPos[i] = myPlayer.translation
		rVel[i] = Vector3.ZERO
		rView[i] = Vector3(0, 0, 10)
		rState[i] = "idle"
			
	myTeam = get_parent().get_parent().teamID - 1
	
	game = Global.game
	set_process(false)
	myPlayer.posI = $PosInd
	
	
func process(_delta):
	
	
	
	
	
	
	if game.recording:
		rPos[game.frame] = myPlayer.translation
		rVel[game.frame] = myPlayer.velocity
		rView[game.frame] = myPlayer.view
		
		
		rState[game.frame] = myPlayer.AI.astate
		
	
	
		
		emit_signal("hudpos", myTeam, myPlayer.myID, myPlayer.translation)
		
	
	
		
		
		
	
	
	

func _getPos():
	return rPos[game.frame]
func _getVel():
	return rVel[game.frame]
func _getLook():
	return rView[game.frame]
func _getAcc():
	return rVel[(game.frame + 1) % 360] - rVel[game.frame]
func _getState():
	return rState[game.frame]
	
func _bibOn():
	mat.set_shader_param("doBibs", true)
func _bibOff():
	mat.set_shader_param("doBibs", false)
