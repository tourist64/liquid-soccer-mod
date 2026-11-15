extends Spatial



var teamID = 0
var posession = false
var AIteam = false
var playDir = 1
var zone = 3
var passDir = Vector3.ZERO
var momentum = false
var opponent = self
var throwTarget = null
var aggression = 0.5
var ball = null
var p1p = Vector3.ZERO
var p2p = Vector3.ZERO
var Game = null
var passto

func _ready():
	$PlayerRoot.set_process(false)
	$PlayerRoot / Player.myTeam = self
	$PlayerRoot / Player.isAI = false
	$PlayerRoot / Player.myID = 1
	$PlayerRoot / Player.connect("posession", self, "_onPosession")
	
	$PlayerRoot2.set_process(false)
	$PlayerRoot2 / Player.myTeam = self
	$PlayerRoot2 / Player.myID = 2
	$PlayerRoot2 / Player.connect("posession", self, "_onPosession")
	



func _ballInBox():
	return false

func _findPass( var _translation, var _passD, var _myID):
	var passto = $PlayerRoot2 / Player
	p1p = Vector3(rand_range(80, 100), 0, rand_range( - 30, 30))
	if ball.player == $PlayerRoot2 / Player:
		passto = $PlayerRoot / Player
		p2p = Vector3(rand_range(80, 100), 0, rand_range( - 30, 30))
	
	passDir = passto.translation - ball.player.translation
	ball.player.isAI = true
	passto.isAI = false
	
	return true
func _findLongPass( var _translation, var _dir, var _myID):
	var passto = $PlayerRoot2 / Player
	p1p = Vector3(rand_range(80, 100), 0, rand_range( - 30, 30))
	if ball.player == $PlayerRoot2 / Player:
		passto = $PlayerRoot / Player
		p2p = Vector3(rand_range(80, 100), 0, rand_range( - 30, 30))
	
	passDir = (passto.translation - ball.player.translation)
	ball.player.isAI = true
	passto.isAI = false
	
	return true
	
func _ballHit():
	pass
func _getPosessionPos( var ID, var trans, var boo):
	
	return trans
func _getPlayPos( var id):
	
	if id == 1:
		return p1p
	else:
		return p2p
func _closestPToP( var crossto):
	var p = $PlayerRoot / Player
	ball.player.isAI = true
	if ball.player == p:
		$PlayerRoot2 / Player.isAI = false
		return $PlayerRoot2 / Player
	else:
		$PlayerRoot / Player.isAI = false
		return $PlayerRoot / Player
	
	
func _shot( var ID, var shotV, var shotcurl, var f):
	pass
func _findThruPass(pos, D, ID):
	var passto = $PlayerRoot2 / Player
	p1p = Vector3(rand_range(80, 100), 0, rand_range( - 30, 30))
	if ball.player == $PlayerRoot2 / Player:
		passto = $PlayerRoot / Player
		p2p = Vector3(rand_range(80, 100), 0, rand_range( - 30, 30))
	var passPos = passto.translation - $PlayerRoot / Player.myGoal
	
	passPos = passto.translation - passPos * 0.2
	passDir = passPos - ball.translation
	ball.player.isAI = true
	passto.isAI = false
	return true
func _switchPControl(_cp):
	pass
func _passTo( var _pto):
	pass
func _onPosession( var id):
	if id == 1:
		$PlayerRoot / Player.isAI = false
		$PlayerRoot2 / Player.isAI = true
	else:
		$PlayerRoot2 / Player.isAI = false
		$PlayerRoot / Player.isAI = true
		

	
