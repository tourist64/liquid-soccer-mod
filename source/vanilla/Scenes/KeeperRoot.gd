extends Spatial

var cam
var label
var game
var myPlayer
var myTeam
var rPos: PoolVector3Array
var rVel: PoolVector3Array
var rView: PoolVector3Array
var rRot: PoolRealArray
var rState: PoolStringArray
var teamID = 0
signal hudpos(teamid, id, pos)
onready var id = $Player.myID
func setColors(shirt, shorts, skin):
	var mat = $Player / PlayerMesh / QuickRigCharacter_Reference / PlayerM.get_surface_material(0)
	mat.set_shader_param("Shirt", shirt)
	mat.set_shader_param("Shirt2", shirt)
	mat.set_shader_param("Shorts", shorts)
	mat.set_shader_param("Skin", skin)
	
	
	


func _ready():
	
	cam = get_node("/root").get_viewport().get_camera()
	label = $Player / Sprite3D / Label
	
	
	
	rPos.resize(360)
	rVel.resize(360)
	rView.resize(360)
	rRot.resize(360)
	rState.resize(360)
	myTeam = get_parent().get_parent().teamID - 1
	if Global.camrot:
		myPlayer.cud = 0
		myPlayer.clr = 1
		myPlayer.jflip = - 1
	else:
		myPlayer.cud = 1
		myPlayer.clr = 0
	myPlayer.mv = $MyView
	myPlayer.mvt = $MyView / Label3D
func process(_delta):
	
	
	
	
	
	if Global.game.recording:
		rPos[game.frame] = myPlayer.translation
		rVel[game.frame] = myPlayer.velocity
		rView[game.frame] = myPlayer.view
		rRot[game.frame] = myPlayer.myMesh.rotation.z
		rState[game.frame] = myPlayer.myAState.get_current_node()
		
	emit_signal("hudpos", myTeam, myPlayer.myID, rPos[Global.game.frame])
	

func _getPos():
	return rPos[game.frame]
func _getLook():
	return rView[game.frame]
func _getVel():
	return rVel[game.frame]
func _getRot():
	return rRot[game.frame]
func _getState():
	return rState[game.frame]
