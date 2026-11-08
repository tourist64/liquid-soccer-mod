extends Node



var cup
# Single-leg cup: Game/Hud/CupViewer read these on every tournament type, and a
# missing property errors out of _halfOver, freezing the match at full time.
var leg = 0
var aggscore = Vector2.ZERO

var pteam

var nrounds: int

var cround: PoolVector2Array
var nround = []

var teams
var balls = []
var teamc = 0
var roundp = 0
var playertie = 0
var rounds = 0
var tourneyName = "Beginner Cup"
func _initCup( var rds, var playerteam, var cp):
	print("initializing tournament")
	cup = cp
	match cp:
		0:
			tourneyName = "Beginner Cup"
		1:
			tourneyName = "Professional Cup"
		2:
			tourneyName = "Chumpions Cup"
		3:
			tourneyName = "International Cup"
		4:
			tourneyName = "Global Cup 2022"
	teams = Global.teams
	pteam = playerteam
	rounds = rds
	
	balls.append(pteam)
	
	var i = 0
	var tt = 0
	while tt < 15:
		if i != pteam:
			balls.append(i)
			tt += 1
		i += 1
			
			
	randomize()
	balls.shuffle()

	nrounds = rounds
	var t = int(pow(2, rounds - 1))
	cround.resize(t)
	teamc = 0
	
	
	for j in range(0, t):
		cround[j] = Vector2(0, 0)

	roundp = 0
	print("initializing tournament done")


func _continueCup( var cp):
	print("initializing tournament")
	cup = cp
	teams = Global.teams
	var res = _loadState()
	if not res:
		return false
		
	return true
	print("restoring tournament done")
func updateCup( var s, var e, var t):
	
	
	for i in range(s, e):
		
		if cround[i].x > cround[i].y:
			balls.append(balls[t])
		else:
			balls.append(balls[t + 1])
		t += 2
		cround.append(Vector2.ZERO)
	
func _gamePlayed( var s1):
	var s = 0
	var e = 8
	var t = 0
	match roundp:
		1:
			s = 8
			e = 12
			t = 16
		2:
			s = 12
			e = 14
			t = 24
		3:
			s = 14
			e = 15
			t = 28
	
	for i in range(s, e):
		if i == playertie:
			cround[playertie] = Vector2(s1.x, s1.y)
		else:
			cround[i] = Vector2(floor(rand_range(0, 4)), floor(rand_range(0, 4)))
			if cround[i].x == cround[i].y:
				if rand_range(0, 1) < 0.6:
					cround[i].x += 1
				else:
					cround[i].y += 1
	roundp += 1
	
	updateCup(s, e, t)

func _loadState():
	var save_game = File.new()
	var fname = "user://cup" + str(cup) + ".save"
	if not save_game.file_exists(fname):
		return false
	
	save_game.open(fname, File.READ)
	
	balls = parse_json(save_game.get_line())
	print(balls)
	cround = save_game.get_var()
	print(cround)
	roundp = int(parse_json(save_game.get_line()))
	pteam = parse_json(save_game.get_line())
	
	save_game.close()
	print("loaded cup")
	return true

func _saveState():
	var save_game = File.new()
	var fname = "user://cup" + str(cup) + ".save"
	save_game.open(fname, File.WRITE)
	
	save_game.store_line(to_json(balls))
	
	
	save_game.store_var(cround)
	
	save_game.store_line(to_json(roundp))
	
	save_game.store_line(to_json(pteam))
	save_game.close()
	print("saved")
