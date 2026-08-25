extends Node




var rounds = []

var cround: PoolVector2Array
var fixtures = [0, 1, 2, 3, 0, 2, 3, 1, 0, 3, 1, 2, 2, 1, 3, 0, 1, 3, 2, 0, 3, 2, 1, 0]
var games = [0, 1, 2, 3, 0, 2, 3, 1, 0, 3, 1, 2, 2, 1, 3, 0, 1, 3, 2, 0, 3, 2, 1, 0]


var teams = []

var playerteam = - 1

var cr = 0
var tr = 3
var justplayed = false
var groupName = "Group 1"
var level
var t = {"id": 0, "name": "teamname", "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0, "tid": 0}
var table = []
var gN = 0
func _ready():
	pass

func _initLeague( var _pteam, var t1, var t2, var t3, var t4, var gn):
	
	teams.clear()
	gN = gn
	teams.append(t1)
	teams.append(t2)
	teams.append(t3)
	teams.append(t4)
	


	if t1 == Global.tTeam:
		playerteam = t1
	elif t2 == Global.tTeam:
		playerteam = t2
	elif t3 == Global.tTeam:
		playerteam = t3
	elif t4 == Global.tTeam:
		playerteam = t4
		
	groupName = "Group " + str(gn)
	
	for i in range(0, 4):
		var d = t.duplicate(false)
		d.name = Global.teams[teams[i]].teamname
		d.id = i
		d.tid = teams[i]
		table.append(d)
	
	
	
	cround.resize(12)
	
	
func _continueGroup( var lev):
	print("restoring world cup")
	level = lev
	teams = Global.teams
	
	
	
	cround.resize(12)
	print("restoring world cup tournament done")
	return true
func _rotateFixtures():
	
	
	var last = fixtures.pop_back()
	fixtures.insert(1, last)
	
	for i in range(0, 4):
		games.append(fixtures[i])
	print(fixtures)

class CustomSort:
	static func sortByPts(a, b):
		if a.pts > b.pts:
			return true
		return false

func compare( var a, var b):
	return a.id < b
	
func findInTable( var tid):
	for i in range(4):
		if table[i].id == tid:
			return i
func _isPlayerTie():
	var j = Global.tournament.cr * 4
	for _i in range(0, 2):
		var t1 = teams[fixtures[j]]
		var t2 = teams[fixtures[j + 1]]
		if t1 == Global.tTeam or t2 == Global.tTeam:
			
			Global.tT1 = t1
			Global.tT2 = t2
			Global.tG = gN
			
			return true
		j += 2
func _gamePlayed( var scor):
	var j = Global.tournament.cr * 4
	for i in range(Global.tournament.cr * 2, Global.tournament.cr * 2 + 2):
		var t1 = teams[fixtures[j]]
		var t2 = teams[fixtures[j + 1]]
		
		if t1 == Global.tTeam or t2 == Global.tTeam:
			
			cround[i].x = int(scor.x)
			cround[i].y = int(scor.y)
		else:
			var add1 = 3 - Global.teams[teams[fixtures[j]]].level
			var add2 = 3 - Global.teams[teams[fixtures[j + 1]]].level
			
			cround[i].x = floor(rand_range(0, 2 + add1))
			cround[i].y = floor(rand_range(0, 2 + add2))
		
	
		t1 = fixtures[j]
		t2 = fixtures[j + 1]
		
		var t1t = findInTable(t1)
		var t2t = findInTable(t2)
		
		
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

	
	
	
func _loadState( var save_game):
	
	table = parse_json(save_game.get_line())
	fixtures = parse_json(save_game.get_line())
	teams = parse_json(save_game.get_line())
	cround = save_game.get_var()
	cround.resize(12)
	games = parse_json(save_game.get_line())
	
	for team in teams:
		if team == Global.tTeam:
			playerteam = Global.tTeam
	
	
	if table[0].name.match ("* W"):
		Global.tType = 3
		Global.isT1Womens = true
		Global.isT2Womens = true
		Global.tournament.tourneyName = "Womens Global Cup 2023"
	return true


func _saveState( var save_game):
	
	save_game.store_line(to_json(table))
	
	
	
	
	save_game.store_line(to_json(fixtures))
	save_game.store_line(to_json(teams))
	save_game.store_var(cround)
	save_game.store_line(to_json(games))
	

func _getWinner():
	return table[0].tid
func _getSecond():
	return table[1].tid
func _getThird():
	return table[2].tid
func _getThirdPoints():
	return table[2].pts
