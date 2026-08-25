extends Node

var gq1 = ["Qatar", "Ecuador", "Senegal", "Holland"]
var gq2 = ["Engurland", "Iran", "USandA", "Wales"]
var gq3 = ["Argentina", "Saudi Arabia", "Mexico", "Polska"]
var gq4 = ["LaFrance", "Australia", "Danmark", "Tunisia"]
var gq5 = ["Espana", "Costa Rica", "Germany", "Japan"]
var gq6 = ["Belgium", "Canadia", "Morocco", "Croatia"]
var gq7 = ["Brasil", "Serbia", "Switzerland", "Cameroon"]
var gq8 = ["Portugal", "Ghana", "Uruguay", "South Korea"]

var gr1 = ["Uruguay", "Ukraine", "Saudi Arabia", "Egypt"]
var gr2 = ["Espana", "Portugal", "Iran", "Morocco"]
var gr3 = ["LaFrance", "Danmark", "Australia", "Peru"]
var gr4 = ["Croatia", "Argentina", "Nigeria", "Iceland"]
var gr5 = ["Brasil", "Switzerland", "Serbia", "Costa Rica"]
var gr6 = ["Sweden", "Mexico", "South Korea", "Germany"]
var gr7 = ["Engurland", "Belgium", "Tunisia", "Panama"]
var gr8 = ["Colombia", "Japan", "Senegal", "Polska"]

var ga1 = ["Mexico", "Cameroon", "Croatia", "Brasil"]
var ga2 = ["Chile", "Holland", "Espana", "Australia"]
var ga3 = ["Ivory Coast", "Japan", "Greece", "Colombia"]
var ga4 = ["Italia", "Engurland", "Costa Rica", "Uruguay"]
var ga5 = ["Honduras", "LaFrance", "Ecuador", "Switzerland"]
var ga6 = ["Nigeria", "Iran", "Argentina", "Bosnia"]
var ga7 = ["USandA", "Ghana", "Portugal", "Germany"]
var ga8 = ["South Korea", "Ukraine", "Algeria", "Belgium"]

var gw1 = ["New Zealand W", "Norway W", "Philippines W", "Switzerland W"]
var gw2 = ["Australia W", "Canada W", "Eire W", "Nigeria W"]
var gw3 = ["Costa Rica W", "Japan W", "Spain W", "Zambia W"]
var gw4 = ["China W", "Denmark W", "England W", "Haiti W"]
var gw5 = ["Holland W", "Portugal W", "USandA W", "Vietnam W"]
var gw6 = ["Brasil W", "France W", "Jamaica W", "Panama W"]
var gw7 = ["Argentina W", "Italia W", "South Africa W", "Sweden W"]
var gw8 = ["Colombia W", "Germany W", "Morocco W", "South Korea W"]

# A ordem dos quartetos segue a ordem dos dois primeiros jogos de cada grupo.
var g26a = ["Mexico", "South Africa", "South Korea", "Czechia"]
var g26b = ["Canadia", "Bosnia", "Qatar", "Switzerland"]
var g26c = ["Haiti", "Scotland", "Brasil", "Morocco"]
var g26d = ["USandA", "Paraguay", "Australia", "Turkey"]
var g26e = ["Cote d'Ivoire", "Ecuador", "Germany", "Curaçao"]
var g26f = ["Holland", "Japan", "Sweden", "Tunisia"]
var g26g = ["Belgium", "Egypt", "Iran", "New Zealand"]
var g26h = ["Espana", "Cabo Verde", "Saudi Arabia", "Uruguay"]
var g26i = ["LaFrance", "Senegal", "Norway", "Iraq"]
var g26j = ["Argentina", "Algeria", "Austria", "Jordan"]
var g26k = ["Portugal", "Colombia", "Congo DR", "Uzbekistan"]
var g26l = ["Engurland", "Croatia", "Ghana", "Panama"]

var active_groups = []
var group_count = 8
var is_2026 = false
var cup = 4
var groups = []
var balls = []
var cround: PoolVector2Array
var playertie = 0
var tourneyName = "Global Cup 2022"
var cr = 0
var roundp = 0
var knockout = null
var t = []
var justplayed = false
var knockoutStage = false
var year = 2022
var semi_losers = []

func _setCup(var c):
	cup = c
	is_2026 = c == 5
	if is_2026:
		active_groups = [g26a, g26b, g26c, g26d, g26e, g26f, g26g, g26h, g26i, g26j, g26k, g26l]
		group_count = 12
		year = 2026
		tourneyName = "World Cup 2026"
		return
	group_count = 8
	match c:
		0:
			active_groups = [gq1, gq2, gq3, gq4, gq5, gq6, gq7, gq8]
			year = 2022
			tourneyName = "Global Cup 2022"
		1:
			active_groups = [gr1, gr2, gr3, gr4, gr5, gr6, gr7, gr8]
			year = 2018
			tourneyName = "Global Cup 2018"
		2:
			active_groups = [ga1, ga2, ga3, ga4, ga5, ga6, ga7, ga8]
			year = 2014
			tourneyName = "Global Cup 2014"
		4:
			active_groups = [gw1, gw2, gw3, gw4, gw5, gw6, gw7, gw8]
			year = 2023
			tourneyName = "Womens Global Cup 2023"

func findTeams(var g):
	for i in range(4):
		var found = -1
		for j in range(Global.teams.size()):
			if Global.teams[j].teamname == g[i]:
				found = j
				break
		if found < 0:
			print("couldn't find team ", g[i])
		t[i] = found

func findTeam(var g, var name):
	for team_name in g:
		if name == team_name:
			return true
	return false

func _qualified(var tname):
	for group in active_groups:
		if findTeam(group, tname):
			return true
	return false

func initGroups(var i, var g):
	findTeams(g)
	var group = load("res://Scenes/WCGroupTournament.tscn").instance()
	groups.append(group)
	group._initLeague(-1, t[0], t[1], t[2], t[3], i)

func _initCup():
	groups.clear()
	balls.clear()
	semi_losers.clear()
	cr = 0
	roundp = 0
	knockoutStage = false
	t.resize(4)
	for i in range(group_count):
		initGroups(i + 1, active_groups[i])
	if is_2026:
		cround.resize(32)
	else:
		cround.resize(16)

func _setupPlayerTie():
	for group in groups:
		group._isPlayerTie()

func _gamePlayed(var score):
	if cr < 3:
		for group in groups:
			group._gamePlayed(score)
	else:
		knockoutGamePlayed(score)
	cr += 1

func _rotateFixtures():
	for group in groups:
		group._rotateFixtures()

class ThirdSort:
	static func sortThird(a, b):
		if a.pts != b.pts:
			return a.pts > b.pts
		var a_diff = a.gf - a.ga
		var b_diff = b.gf - b.ga
		if a_diff != b_diff:
			return a_diff > b_diff
		return a.gf > b.gf

func _knockoutStage():
	knockoutStage = true
	balls.clear()
	semi_losers.clear()
	if is_2026:
		var thirds = []
		for group in groups:
			balls.append(group._getWinner())
			balls.append(group._getSecond())
			thirds.append(group._getThirdEntry())
		thirds.sort_custom(ThirdSort, "sortThird")
		for i in range(8):
			balls.append(thirds[i].tid)
		cround.resize(32)
	else:
		cround.resize(16)
		for group in groups:
			balls.append(group._getWinner())
			balls.append(group._getSecond())

func _score_for_match(index, supplied):
	if index == playertie:
		return Vector2(supplied.x, supplied.y)
	var score = Vector2(floor(rand_range(0, 4)), floor(rand_range(0, 4)))
	if score.x == score.y:
		score.x += 1
	return score

func _winner_for_match(index):
	var teams_for_match = _knockout_teams(index)
	var result = cround[index]
	if result.x >= result.y:
		return [teams_for_match[0], teams_for_match[1]]
	return [teams_for_match[1], teams_for_match[0]]

func _knockout_teams(index):
	if is_2026:
		if index < 16:
			return [balls[index * 2], balls[index * 2 + 1]]
		if index < 24:
			var r16 = 32 + (index - 16) * 2
			return [balls[r16], balls[r16 + 1]]
		if index < 28:
			var qf = 48 + (index - 24) * 2
			return [balls[qf], balls[qf + 1]]
		if index < 30:
			var sf = 56 + (index - 28) * 2
			return [balls[sf], balls[sf + 1]]
		if index == 30:
			return [semi_losers[0], semi_losers[1]]
		return [balls[60], balls[61]]
	if index < 8:
		return [balls[index * 2], balls[index * 2 + 1]]
	var old_round = 16 + (index - 8) * 2
	return [balls[old_round], balls[old_round + 1]]

func _append_winners(start, end):
	for i in range(start, end):
		var winners = _winner_for_match(i)
		balls.append(winners[0])
		if is_2026 and start == 28:
			semi_losers.append(winners[1])

func knockoutGamePlayed(var score):
	if is_2026:
		var start = 0
		var end = 16
		match roundp:
			0:
				start = 0
				end = 16
			1:
				start = 16
				end = 24
			2:
				start = 24
				end = 28
			3:
				start = 28
				end = 30
			4:
				start = 30
				end = 32
		for i in range(start, end):
			cround[i] = _score_for_match(i, score)
		if roundp < 4:
			_append_winners(start, end)
		roundp += 1
		return

	var s = 8
	var e = 12
	match roundp:
		1:
			s = 8
			e = 12
		2:
			s = 12
			e = 14
		3:
			s = 14
			e = 15
	for i in range(s, e):
		cround[i] = _score_for_match(i, score)
	_append_winners(s, e)
	roundp += 1

func _loadState():
	var save_game = File.new()
	var fname = "user://globalcup.save"
	if is_2026:
		fname = "user://globalcup2026.save"
	if Global.tType == 3:
		fname = "user://wglobalcup.save"
	if not save_game.file_exists(fname):
		return false
	save_game.open(fname, File.READ)
	Global.tTeam = parse_json(save_game.get_line())
	cr = parse_json(save_game.get_line())
	for group in groups:
		group._loadState(save_game)
	if cr > 2:
		knockoutStage = true
		balls = parse_json(save_game.get_line())
		cround = save_game.get_var()
		roundp = int(parse_json(save_game.get_line()))
		if is_2026 and not save_game.eof_reached():
			semi_losers = parse_json(save_game.get_line())
	save_game.close()
	return true

func _saveState():
	var save_game = File.new()
	var fname = "user://globalcup.save"
	if is_2026:
		fname = "user://globalcup2026.save"
	if Global.tType == 3:
		fname = "user://wglobalcup.save"
	save_game.open(fname, File.WRITE)
	save_game.store_line(to_json(Global.tTeam))
	save_game.store_line(to_json(cr))
	for group in groups:
		group._saveState(save_game)
	if cr > 2:
		save_game.store_line(to_json(balls))
		save_game.store_var(cround)
		save_game.store_line(to_json(roundp))
		if is_2026:
			save_game.store_line(to_json(semi_losers))
	save_game.close()

func _continueCup(var cp):
	_initCup()
	return _loadState()
