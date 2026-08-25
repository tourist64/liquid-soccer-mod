extends Node


var rounds = []

var cround: PoolVector2Array
var fixtures = []


var teams = []

var playerteam = 0

var cr = 1
var tr = 30
var justplayed = false
var nteams = 16
var level
var t = {"id": 0, "name": "teamname", "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0}
var table = []
var maxpoints = 3
var pointsleft = 3
var doneCeleb = false
var leg = 0
func _ready():
	pass

func _initLeague( var eteams, var nrounds, var pteam, var lev):
	
	level = lev
	teams.clear()
	var a = 0
	var entered = 0
	nteams = min(eteams.size(), 18)
	while entered < nteams:
		teams.append(eteams[a])
		entered += 1
		a += 1
	playerteam = eteams[pteam]
	tr = nrounds * (nteams - 1)
	maxpoints = tr * 3
	pointsleft = maxpoints
	
	for i in range(nteams):
		var d = t.duplicate(false)
		d.name = Global.teams[eteams[i]].teamname
		d.id = i
		table.append(d)
		fixtures.append(i)
	cr = 1
	
	
	cround.resize(nteams / 2)
	print("shuffling")
	
func _continueLeague( var lev):
	print("continuing tournament")
	level = lev
	teams = Global.teams
	var res = _loadState()
	if not res:
		return false
	cround.resize(nteams / 2)
	return true
	
func _rotateFixtures():
	
	
	var last = fixtures.pop_back()
	fixtures.insert(1, last)
	print(fixtures)


class CustomSort:
	static func sortByPts(a, b):
		if a.pts > b.pts:
			return true
		elif a.pts == b.pts:
			if a.gf - a.ga > b.gf - b.ga:
				return true
		return false

func compare( var a, var b):
	return a.id < b
func findInTable( var tid):
	for i in range(16):
		if table[i].id == tid:
			return i
			
func _gamePlayed( var scor):
	var j = 0
	for i in range(0, nteams / 2):
		if teams[fixtures[j]] == playerteam or teams[fixtures[nteams - j - 1]] == playerteam:
			
			cround[i].x = int(scor.x)
			cround[i].y = int(scor.y)
		else:
			
			cround[i].x = floor(rand_range(0, 4))
			cround[i].y = floor(rand_range(0, 3))
			
			
			
	
		
		var t1 = fixtures[j]
		var t2 = fixtures[j + 1]
		print("CR = ", cr)
		if (cr > (nteams)):
			print("second half of season")
			var tmp = t2
			t2 = t1
			t1 = tmp
		
		var t1t = findInTable(t1)
		var t2t = findInTable(t2)
		print(t1t, " ", table[t1t].name)
		print(t2t, " ", table[t2t].name)
		if cround[i].x > cround[i].y:
			table[t1t].pts += 3
			table[t1t].w += 1
			table[t2t].l += 1
			
		elif cround[i].y > cround[i].x:
			table[t2t].pts += 3
			table[t2t].w += 1
			table[t1t].l += 1
		else:
			table[t1t].pts += 1
			table[t2t].pts += 1
			table[t1t].d += 1
			table[t2t].d += 1
			
		table[t1t].gf += cround[i].x
		table[t1t].ga += cround[i].y
		table[t2t].ga += cround[i].x
		table[t2t].gf += cround[i].y
		
		j += 2
	
	
	cr += 1
	justplayed = true
	table.sort_custom(CustomSort, "sortByPts")
	pointsleft -= 3
	
	
func _checkWinner():
	
	var pd = (table[0].pts + 3) - (table[1].pts + 3)
	if pd > pointsleft:
		return true
		
func _loadState():
	var save_game = File.new()
	var fname = "user://league" + str(level) + ".save"
	if not save_game.file_exists(fname):
		return false
	
	save_game.open(fname, File.READ)

	table = parse_json(save_game.get_line())
	
	cr = int(parse_json(save_game.get_line()))
	playerteam = parse_json(save_game.get_line())
	fixtures = parse_json(save_game.get_line())
	teams = parse_json(save_game.get_line())
	nteams = teams.size()
	tr = (nteams - 1) * 2
	save_game.close()
	print("loaded league ")
	return true

func _saveState():
	var save_game = File.new()
	var fname = "user://league" + str(level) + ".save"
	save_game.open(fname, File.WRITE)
	
	save_game.store_line(to_json(table))
	
	
	
	
	save_game.store_line(to_json(cr))
	
	save_game.store_line(to_json(playerteam))
	
	if justplayed:
		_rotateFixtures()
	save_game.store_line(to_json(fixtures))
	save_game.store_line(to_json(teams))
	
	save_game.close()
	print("saved")
func _didWeWin( var _pts):
	return false
