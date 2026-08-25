extends Node





var gq1 = ["Bayern Munch", "FC Copenhagen", "Galatasaray", "Money Utd"]
var gq2 = ["Royal Ars", "PSV Eindhoven ", "RC Lens", "Sevilla"]
var gq3 = ["Royal Mudrid", "Napoli", "SC Braga", "Union Berlin"]
var gq4 = ["Royal Sociedad", "Inter Milano", "Benfico", "RB Salzburg"]
var gq5 = ["Athletic Mads", "Lazio", "Feyenoord", "Queens Celtic"]
var gq6 = ["B Dortmund", "PSG", "AC Milano", "Toon Utd"]
var gq7 = ["Money Citeh", "RB Leibzigs", "Young Boys", "Red Star Belgrade"]
var gq8 = ["Barcaloony", "FC Port", "Shaktar Donetsk", "Royale Antwerps"]


var g1
var g2
var g3
var g4
var g5
var g6
var g7
var g8

var cup = 4
var leg = 1
var groups = []
var balls = []
var cround: PoolVector2Array
var playertie = 0
var tourneyName = "Chumpions League 2023-24"
var cr = 0
var roundp = 0
var knockout = null
var t = []
var justplayed = false
var knockoutStage = false
var aggscore = Vector2.ZERO
var year = 2023
func _setCup( var _c):
	g1 = gq1
	g2 = gq2
	g3 = gq3
	g4 = gq4
	g5 = gq5
	g6 = gq6
	g7 = gq7
	g8 = gq8
	year = 2023
	
func findTeams( var g):
	
	for i in range(0, 4):
		for j in range(Global.teams.size()):
			if Global.teams[j].teamname == g[i]:
				t[i] = j
				break
		if t[i] == 0:
			print("couldn't find team ", g[i])
func findTeam( var g, var name):
	for i in range(0, 4):
		if name == g[i]:
			return true
		
	return false
func _qualified( var tname):
	
	
	if findTeam(g1, tname):
		return true
	elif findTeam(g2, tname):
		return true
	elif findTeam(g3, tname):
		return true
	elif findTeam(g4, tname):
		return true
	elif findTeam(g5, tname):
		return true
	elif findTeam(g6, tname):
		return true
	elif findTeam(g7, tname):
		return true
	elif findTeam(g8, tname):
		return true
	print("no team ", tname)
	return false
func initGroups( var i, var g):
	
	findTeams(g)
	var group = load("res://Scenes/WCGroupTournament.tscn").instance()
	groups.append(group)
	group._initLeague( - 1, t[0], t[1], t[2], t[3], i)
	
	
func _initCup():
	t.resize(4)
	initGroups(1, g1)
	initGroups(2, g2)
	initGroups(3, g3)
	initGroups(4, g4)
	initGroups(5, g5)
	initGroups(6, g6)
	initGroups(7, g7)
	initGroups(8, g8)

func _setupPlayerTie():
	for i in range(0, 8):
		groups[i]._isPlayerTie()


func _gamePlayed( var score):
	
	
	if cr < 6:
		for i in range(0, 8):
			
			groups[i]._gamePlayed(score)
				
			
			
		
		
		
		
	else:
		knockoutGamePlayed(score)
	cr += 1
func _rotateFixtures():
	for i in range(0, 8):
		groups[i]._rotateFixtures()
func _knockoutStage():
	
	
	knockoutStage = true
	cround.resize(16)
	balls.resize(16)
	var j = 0
	for i in range(0, 8):
		balls[j] = groups[i]._getWinner()
		balls[j + 8] = groups[i]._getSecond()
		j += 1
func knockoutGamePlayed( var s1):
	var s = 0
	var e = 8
	var tt = 0
	match roundp:
		1:
			s = 8
			e = 12
			tt = 16
		2:
			s = 12
			e = 14
			tt = 24
		3:
			s = 14
			e = 15
			tt = 28
			leg = 2
	
	for i in range(s, e):
		if i == playertie:
			if leg == 1:
				cround[playertie] = Vector2(s1.x, s1.y)
				aggscore = Vector2(s1.x, s1.y)
			elif leg == 2:
				cround[playertie] = Vector2(s1.y, s1.x)
		else:
			cround[i] += Vector2(floor(rand_range(0, 4)), floor(rand_range(0, 4)))
			if cround[i].x == cround[i].y:
				if rand_range(0, 1) < 0.6:
					cround[i].x += 1
				else:
					cround[i].y += 1
	if leg == 2:
		roundp += 1
		leg = 1
		
		updateCup(s, e, tt)
	else:
		leg = 2
	
	
func updateCup( var s, var e, var tt):
	
	
	for i in range(s, e):
		
		if cround[i].x > cround[i].y:
			balls.append(balls[tt])
		else:
			balls.append(balls[tt + 1])
		tt += 2
		cround.append(Vector2.ZERO)
func _loadState():
	
	var save_game = File.new()
	var fname = "user://chumps.save"
	if not save_game.file_exists(fname):
		return false
	
	save_game.open(fname, File.READ)
	
	
	Global.tTeam = parse_json(save_game.get_line())
	
	cr = parse_json(save_game.get_line())
	
	for i in range(0, 8):
		groups[i]._loadState(save_game)

	if cr > 5:
		knockoutStage = true
		balls = parse_json(save_game.get_line())
		
		cround = save_game.get_var()
		
		roundp = int(parse_json(save_game.get_line()))
		
		
		leg = int(parse_json(save_game.get_line()))
		
	save_game.close()
	return true
func _saveState():
	
	
	var save_game = File.new()
	var fname = "user://chumps.save"
	save_game.open(fname, File.WRITE)
	
	save_game.store_line(to_json(Global.tTeam))
	
	save_game.store_line(to_json(cr))
	
	for i in range(0, 8):
			groups[i]._saveState(save_game)
			
	if cr > 2:
		save_game.store_line(to_json(balls))
	
		save_game.store_var(cround)
	
		save_game.store_line(to_json(roundp))
	
		save_game.store_line(to_json(leg))
	save_game.close()
	print("saved")
	
func _continueCup( var cp):
	print("restoring tournament")
	
	_initCup()
	var res = _loadState()
	if not res:
		return false
	print("restoring tournament done")
	return true
	
