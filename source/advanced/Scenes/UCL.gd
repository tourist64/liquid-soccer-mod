extends Node

# New UCL (tType 6): the 2026/27 Champions League, played 8v8.
# League phase: 36 clubs in one table, 8 matchdays against 8 different opponents.
# 1st-8th go straight to the last 16, 9th-24th play a knockout play-off, 25th-36th are out.
# Knockouts are single matches (penalties if level): play-off, last 16, quarters, semis, final.
# Matches the player isn't in are simulated from club strength, so big clubs usually win.

const TEAM_DIR = "res://Teams/6/"
const SAVE_FILE = "user://newucl2627.save"
const MATCHDAYS = 8
const ROUND_NAMES = ["Knockout play-off", "Round of 16", "Quarter-finals", "Semi-finals", "Final"]

# Club strength (about 65-92) for simulated results; also orders the clubs.
const RATINGS = {"PSG": 92, "Real Madrid": 91, "Arsenal": 91, "Bayern Munich": 91, "Barcelona": 90,
	"Man City": 89, "Liverpool": 89, "Inter": 87, "Atletico Madrid": 85, "Napoli": 84, "Dortmund": 83,
	"Aston Villa": 83, "Man Utd": 82, "Roma": 81, "Porto": 80, "Sporting CP": 80, "Villarreal": 80,
	"RB Leipzig": 80, "Fenerbahce": 80, "Galatasaray": 80, "Como": 79, "Stuttgart": 79, "Real Betis": 79,
	"Lille": 78, "PSV": 77, "Feyenoord": 77, "Lens": 77, "Club Brugge": 76, "Shakhtar Donetsk": 75,
	"AEK Athens": 74, "Bodo Glimt": 74, "Slavia Prague": 73, "LASK": 70, "Viking": 69, "Sabah": 67,
	"Slovan Bratislava": 67}

# Simulated scorelines: each side's expected goals is BASE_GOALS scaled by the strength gap.
# A 25-point gap (PSG v Slovan Bratislava) is about 3.5 v 0.5 goals; level clubs about 1.3 each.
const BASE_GOALS = 1.3
const GAP_FACTOR = 0.04
const HOME_EDGE = 1.5
# In the knockouts, AI clubs rated this high (and any finalist) play with the sharpest AI (level 0).
const SHARP_AI_RATING = 84

# Read by Game.gd / Hud.gd like the other tournaments.
var cup = 2
var leg = 0
var aggscore = Vector2.ZERO
var knockoutStage = false

var files = []
var names = []
var shorts = []
var ratings = []
var tTeam = -1
var fixtures = []      # [matchday] -> Array of [home, away]
var results = []       # [matchday] -> Array of [home goals, away goals] (empty until played)
var matchday = 0
var table = []         # [club] -> {"p", "w", "d", "l", "gf", "ga", "pts"}
var koRound = 0
var ties = []          # current knockout round: Array of [a, b]
var koResults = []     # [round] -> Array of {"a", "b", "s": [a goals, b goals], "pens", "w"}
var champion = -1
var playerOut = false

func _init():
	for f in _sortedFiles():
		var t = load(TEAM_DIR + f + ".tres")
		files.append(f)
		names.append(t.teamname)
		shorts.append(t.shortname)
		ratings.append(RATINGS[f])

func _sortedFiles():
	var out = RATINGS.keys()
	out.sort_custom(self, "_byRating")
	return out

func _byRating(a, b):
	if RATINGS[a] != RATINGS[b]:
		return RATINGS[a] > RATINGS[b]
	return a < b

func path(i):
	return TEAM_DIR + files[i] + ".tres"

# --- New tournament -------------------------------------------------------------------------

func start(player):
	randomize()
	tTeam = player
	matchday = 0
	koRound = 0
	ties = []
	koResults = []
	champion = -1
	playerOut = false
	knockoutStage = false
	table = []
	for _i in range(files.size()):
		table.append({"p": 0, "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0})
	_makeFixtures()
	saveState()

# 8 rounds of a shuffled round-robin (circle method): every club plays 8 different opponents,
# about half at home.
func _makeFixtures():
	var order = range(files.size())
	order.shuffle()
	var n = order.size()
	var rounds = range(n - 1)
	rounds.shuffle()
	fixtures = []
	results = []
	for m in range(MATCHDAYS):
		var r = rounds[m]
		var rot = [order[0]]
		for k in range(1, n):
			rot.append(order[1 + (k - 1 + r) % (n - 1)])
		var day = []
		for k in range(n / 2):
			var a = rot[k]
			var b = rot[n - 1 - k]
			if (k + m) % 2 == 0:
				day.append([a, b])
			else:
				day.append([b, a])
		fixtures.append(day)
		results.append([])

# --- What the player plays next -------------------------------------------------------------

# [home, away] of the player's next match, or [] if there is none.
func nextMatch():
	if champion != -1 or playerOut:
		return []
	if not knockoutStage:
		for f in fixtures[matchday]:
			if f[0] == tTeam or f[1] == tTeam:
				return f
		return []
	for t in ties:
		if t[0] == tTeam or t[1] == tTeam:
			return t
	return []

func isFinal():
	return knockoutStage and koRound == 4

func stageName():
	if champion != -1:
		return "Champions: " + names[champion]
	if not knockoutStage:
		return "League phase - Matchday " + str(matchday + 1) + " of " + str(MATCHDAYS)
	return ROUND_NAMES[koRound]

# --- Results --------------------------------------------------------------------------------

# Called by Hud.gd after the player's match: score.x is the home side (team1), score.y the away.
func _gamePlayed(score):
	var f = nextMatch()
	if f.size() == 2:
		_advance([int(score.x), int(score.y)])
	saveState()

# Plays out the rest of the current matchday or round around the player's result.
func _advance(playerScore):
	if not knockoutStage:
		var day = []
		for f in fixtures[matchday]:
			var s = playerScore if (playerScore != null and (f[0] == tTeam or f[1] == tTeam)) else _simScore(f[0], f[1], true)
			day.append(s)
			_record(f[0], f[1], s)
		results[matchday] = day
		matchday += 1
		if matchday >= MATCHDAYS:
			_startKnockouts()
		return
	var rnd = []
	var winners = []
	for t in ties:
		var s
		var pens = false
		var w
		if playerScore != null and (t[0] == tTeam or t[1] == tTeam):
			s = playerScore
			# Game.gd adds the shootout to the score, so a level score here can't happen; just in case:
			w = t[0] if s[0] >= s[1] else t[1]
		else:
			s = _simScore(t[0], t[1], false)
			if s[0] == s[1]:
				pens = true
				w = t[0] if randf() < _penEdge(t[0], t[1]) else t[1]
			else:
				w = t[0] if s[0] > s[1] else t[1]
		if (t[0] == tTeam or t[1] == tTeam) and w != tTeam:
			playerOut = true
		rnd.append({"a": t[0], "b": t[1], "s": s, "pens": pens, "w": w})
		winners.append(w)
	koResults.append(rnd)
	_nextRound(winners)

func _record(h, a, s):
	for side in [[h, s[0], s[1]], [a, s[1], s[0]]]:
		var row = table[side[0]]
		row["p"] += 1
		row["gf"] += side[1]
		row["ga"] += side[2]
		if side[1] > side[2]:
			row["w"] += 1
			row["pts"] += 3
		elif side[1] == side[2]:
			row["d"] += 1
			row["pts"] += 1
		else:
			row["l"] += 1

func _simScore(a, b, homeEdge):
	var gap = ratings[a] - ratings[b] + (HOME_EDGE if homeEdge else 0.0)
	return [_poisson(clamp(BASE_GOALS * exp(GAP_FACTOR * gap), 0.25, 4.0)),
		_poisson(clamp(BASE_GOALS * exp(- GAP_FACTOR * gap), 0.25, 4.0))]

func _poisson(lam):
	var l = exp(- lam)
	var k = 0
	var p = randf()
	while p > l and k < 9:
		k += 1
		p *= randf()
	return k

# Chance the first club wins a shootout: slightly favours the stronger side.
func _penEdge(a, b):
	return clamp(0.5 + 0.01 * (ratings[a] - ratings[b]), 0.35, 0.65)

# --- Table and knockouts --------------------------------------------------------------------

# Club indices from 1st to 36th: points, goal difference, goals scored, then strength.
func standings():
	var order = range(files.size())
	order.sort_custom(self, "_byTable")
	return order

func _byTable(a, b):
	var ta = table[a]
	var tb = table[b]
	if ta.pts != tb.pts:
		return ta.pts > tb.pts
	if ta.gf - ta.ga != tb.gf - tb.ga:
		return ta.gf - ta.ga > tb.gf - tb.ga
	if ta.gf != tb.gf:
		return ta.gf > tb.gf
	return ratings[a] > ratings[b]

func position(i):
	return standings().find(i) + 1

func _startKnockouts():
	knockoutStage = true
	koRound = 0
	var st = standings()
	if st.find(tTeam) >= 24:
		playerOut = true
	# 9th v 24th, 10th v 23rd ... 16th v 17th; the higher-placed club is at home.
	ties = []
	for k in range(8):
		ties.append([st[8 + k], st[23 - k]])
	koResults = []

func _nextRound(winners):
	koRound += 1
	if koRound == 1:
		# Last 16: the top 8 meet the play-off winners (1st plays the 16th/17th winner and so on),
		# ordered so 1st and 2nd can only meet in the final.
		var st = standings()
		var seeded = []
		for k in range(8):
			seeded.append([st[k], winners[7 - k]])
		ties = [seeded[0], seeded[7], seeded[3], seeded[4], seeded[1], seeded[6], seeded[2], seeded[5]]
		return
	if winners.size() == 1:
		champion = winners[0]
		ties = []
		return
	ties = []
	for k in range(0, winners.size(), 2):
		ties.append([winners[k], winners[k + 1]])

# A round the player isn't in (e.g. the play-off when they finished top 8).
func simulateRound():
	_advance(null)
	saveState()

# After the player is knocked out: play everything out to the final.
func simulateToEnd():
	while champion == -1:
		_advance(null)
	saveState()

# --- Save / load ----------------------------------------------------------------------------

func saveState():
	var f = File.new()
	if f.open(SAVE_FILE, File.WRITE) != OK:
		return
	f.store_line(to_json({"files": files, "tTeam": tTeam, "fixtures": fixtures, "results": results,
		"matchday": matchday, "table": table, "koRound": koRound, "ties": ties, "koResults": koResults,
		"champion": champion, "playerOut": playerOut, "knockoutStage": knockoutStage}))
	f.close()

static func hasSave():
	return File.new().file_exists(SAVE_FILE)

func loadState():
	var f = File.new()
	if not f.file_exists(SAVE_FILE) or f.open(SAVE_FILE, File.READ) != OK:
		return false
	var d = parse_json(f.get_line())
	f.close()
	if typeof(d) != TYPE_DICTIONARY or str(d.get("files", [])) != str(files):
		return false
	tTeam = int(d.tTeam)
	fixtures = _ints(d.fixtures)
	results = _ints(d.results)
	matchday = int(d.matchday)
	table = []
	for row in d.table:
		var r = {}
		for k in row:
			r[k] = int(row[k])
		table.append(r)
	koRound = int(d.koRound)
	ties = _ints(d.ties)
	koResults = []
	for rnd in d.koResults:
		var rr = []
		for t in rnd:
			rr.append({"a": int(t.a), "b": int(t.b), "s": _ints(t.s), "pens": bool(t.pens), "w": int(t.w)})
		koResults.append(rr)
	champion = int(d.champion)
	playerOut = bool(d.playerOut)
	knockoutStage = bool(d.knockoutStage)
	return true

# JSON brings numbers back as floats; turn nested arrays of numbers back into ints.
func _ints(v):
	if typeof(v) == TYPE_ARRAY:
		var out = []
		for x in v:
			out.append(_ints(x))
		return out
	if typeof(v) == TYPE_REAL:
		return int(v)
	return v
