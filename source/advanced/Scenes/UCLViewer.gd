extends Control

# New UCL screen: pick a club, then the league table / knockout bracket and the next match.
# Everything is built in code on top of the shared UI theme.

const UCL = preload("res://Scenes/UCL.gd")

const BG = Color(0.03, 0.06, 0.20)
const PANEL = Color(0.06, 0.11, 0.30, 0.92)
const LINE = Color(0.20, 0.30, 0.60, 0.6)
const GOLD = Color(0.96, 0.80, 0.44)
const WHITE = Color(0.95, 0.96, 1.0)
const DIM = Color(0.62, 0.68, 0.85)
const ZONE_TOP = Color(0.10, 0.45, 0.28, 0.55)
const ZONE_PLAYOFF = Color(0.14, 0.32, 0.66, 0.45)
const ZONE_OUT = Color(0.40, 0.12, 0.16, 0.35)
const ME = Color(0.96, 0.80, 0.44, 0.22)

var ucl = null
var page = null
var showTable = false
var busy = false
var saveBtn = null
var fTitle
var fBig
var fMed
var fSmall
var trans

func _ready():
	Global.tType = 6
	Global.isPenalties = false
	fTitle = _font("res://Res/Republiko-Outline3.otf", 34)
	fBig = _font("res://Res/OLDBLEND.ttf", 24)
	fMed = _font("res://Res/OLDBLEND.ttf", 18)
	fSmall = _font("res://Res/OLDBLEND.ttf", 13)
	_rect(self, Vector2.ZERO, Vector2(1031, 580), BG)
	# A few faint stars in the background.
	var rng = RandomNumberGenerator.new()
	rng.seed = 2526
	for _i in range(40):
		var s = rng.randf_range(1.0, 2.5)
		_rect(self, Vector2(rng.randf_range(0, 1031), rng.randf_range(0, 580)), Vector2(s, s), Color(1, 1, 1, rng.randf_range(0.08, 0.3)))
	if Global.tournament != null and Global.tournament.get("koResults") != null:
		ucl = Global.tournament
	_show()
	trans = load("res://Scenes/Transition.tscn").instance()
	add_child(trans)
	trans._wipeOn()

func _show():
	if page:
		page.queue_free()
	page = Control.new()
	page.rect_size = Vector2(1031, 580)
	add_child(page)
	if trans:
		move_child(trans, get_child_count() - 1)
	if ucl == null:
		_picker()
	elif ucl.knockoutStage and not showTable:
		_bracket()
	else:
		_league()

# --- Pick a club ----------------------------------------------------------------------------

func _picker():
	_title("CHAMPIONS LEAGUE 2026/27")
	_label(page, "Pick your club", Vector2(0, 62), Vector2(1031, 30), fBig, WHITE, Label.ALIGN_CENTER)
	var tmp = UCL.new()
	for i in range(tmp.files.size()):
		var c = i % 6
		var r = i / 6
		var b = _button(page, tmp.names[i], Vector2(22 + c * 166, 102 + r * 64), Vector2(156, 54), "_pick", [i], fMed)
		if i == 0:
			b.grab_focus()
	tmp.free()
	_button(page, "back", Vector2(22, 500), Vector2(150, 56), "_menu", [], fBig)
	# Two separate campaigns: pick a slot, then continue it or pick a club to start a new one there.
	for n in [1, 2]:
		var tag = ("> slot " if n == _slot() else "slot ") + str(n) + (" (saved)" if UCL.hasSave(n) else "")
		_button(page, tag, Vector2(190 + (n - 1) * 290, 500), Vector2(280, 56), "_setSlot", [n], fMed)
	if UCL.hasSave(_slot()):
		_button(page, "continue saved", Vector2(780, 500), Vector2(228, 56), "_continue", [], fBig)

func _slot():
	return Global.get_meta("ucl_slot") if Global.has_meta("ucl_slot") else 1

func _setSlot(n):
	Global.set_meta("ucl_slot", n)
	_show()

func _pick(i):
	ucl = UCL.new()
	ucl.slot = _slot()
	ucl.start(i)
	Global.tournament = ucl
	_show()

func _continue():
	var u = UCL.new()
	u.slot = _slot()
	if u.loadState():
		ucl = u
		Global.tournament = ucl
		showTable = false
		_show()
	else:
		u.free()

# --- League phase: table + next match -------------------------------------------------------

func _league():
	_title("CHAMPIONS LEAGUE 2026/27")
	_label(page, "Slot " + str(ucl.slot) + "  -  " + ucl.stageName(), Vector2(440, 16), Vector2(570, 30), fMed, WHITE, Label.ALIGN_RIGHT)
	_table(Vector2(18, 58))
	var x = 600
	_rect(page, Vector2(x, 58), Vector2(412, 512), PANEL)
	var pos = ucl.position(ucl.tTeam)
	_label(page, ucl.names[ucl.tTeam], Vector2(x + 14, 66), Vector2(390, 30), fBig, GOLD)
	_label(page, _ordinal(pos) + " in the table, " + str(ucl.table[ucl.tTeam].pts) + " pts", Vector2(x + 14, 96), Vector2(390, 22), fMed, WHITE)
	var y = 132
	_label(page, "Your results", Vector2(x + 14, y), Vector2(390, 22), fMed, DIM)
	y += 24
	for m in range(ucl.matchday):
		for k in range(ucl.fixtures[m].size()):
			var f = ucl.fixtures[m][k]
			if f[0] == ucl.tTeam or f[1] == ucl.tTeam:
				var s = ucl.results[m][k]
				var txt = "MD" + str(m + 1) + "   " + ucl.names[f[0]] + "  " + str(s[0]) + "-" + str(s[1]) + "  " + ucl.names[f[1]]
				var mine = s[0] if f[0] == ucl.tTeam else s[1]
				var theirs = s[1] if f[0] == ucl.tTeam else s[0]
				var col = Color(0.5, 0.9, 0.6) if mine > theirs else (WHITE if mine == theirs else Color(1.0, 0.55, 0.55))
				_label(page, txt, Vector2(x + 14, y), Vector2(390, 20), fSmall, col)
				y += 20
	if ucl.matchday == 0:
		_label(page, "No games yet.", Vector2(x + 14, y), Vector2(390, 20), fSmall, DIM)
	_nextBox(Vector2(x, 360), 412)
	if ucl.knockoutStage:
		_button(page, "bracket", Vector2(x + 14, 508), Vector2(120, 52), "_toggleTable", [], fMed)
	_saveButton(Vector2(x + 146, 508), Vector2(120, 52))
	_button(page, "menu", Vector2(x + 278, 508), Vector2(120, 52), "_menu", [], fMed)

func _table(at):
	var w = 566
	_rect(page, at, Vector2(w, 512), PANEL)
	var cols = [["#", 8], ["Club", 34], ["P", 318], ["W", 350], ["D", 380], ["L", 410], ["GD", 446], ["Pts", 506]]
	for c in cols:
		_label(page, c[0], at + Vector2(c[1], 4), Vector2(50, 16), fSmall, DIM)
	var st = ucl.standings()
	for r in range(st.size()):
		var i = st[r]
		var y = at.y + 22 + r * 13.0
		var zone = ZONE_TOP if r < 8 else (ZONE_PLAYOFF if r < 24 else ZONE_OUT)
		_rect(page, Vector2(at.x + 2, y), Vector2(w - 4, 12.5), zone)
		if i == ucl.tTeam:
			_rect(page, Vector2(at.x + 2, y), Vector2(w - 4, 12.5), ME)
		var t = ucl.table[i]
		var col = GOLD if i == ucl.tTeam else WHITE
		var gd = t.gf - t.ga
		var vals = [str(r + 1), ucl.names[i], str(t.p), str(t.w), str(t.d), str(t.l), ("+" if gd > 0 else "") + str(gd), str(t.pts)]
		for c in range(cols.size()):
			_label(page, vals[c], Vector2(at.x + cols[c][1], y - 1), Vector2(280 if c == 1 else 50, 14), fSmall, col)
	_label(page, "1-8 last 16    9-24 play-off    25-36 out", Vector2(at.x + 8, at.y + 494), Vector2(w, 16), fSmall, DIM)

# --- Knockouts: bracket + next match --------------------------------------------------------

func _bracket():
	_title("CHAMPIONS LEAGUE 2026/27")
	_label(page, ucl.stageName(), Vector2(500, 16), Vector2(510, 30), fMed, WHITE, Label.ALIGN_RIGHT)
	var counts = [8, 8, 4, 2, 1]
	var colW = 196
	for c in range(5):
		var x = 16 + c * (colW + 4)
		_label(page, UCL.ROUND_NAMES[c], Vector2(x, 54), Vector2(colW, 20), fSmall, GOLD, Label.ALIGN_CENTER)
		var slot = 360.0 / counts[c]
		for k in range(counts[c]):
			var y = 76 + slot * k + (slot - 42) / 2
			_tieBox(Vector2(x, y), colW, c, k)
	_nextBox(Vector2(16, 446), 1000)
	_saveButton(Vector2(16, 512), Vector2(180, 52))
	_button(page, "table", Vector2(612, 512), Vector2(180, 52), "_toggleTable", [], fMed)
	_button(page, "menu", Vector2(818, 512), Vector2(180, 52), "_menu", [], fMed)

func _tieBox(at, w, rnd, k):
	_rect(page, at, Vector2(w, 42), PANEL)
	var a = -1
	var b = -1
	var s = null
	var win = -1
	var pens = false
	if rnd < ucl.koResults.size():
		var t = ucl.koResults[rnd][k]
		a = t.a
		b = t.b
		s = t.s
		win = t.w
		pens = t.pens
	elif rnd == ucl.koRound and k < ucl.ties.size():
		a = ucl.ties[k][0]
		b = ucl.ties[k][1]
	var rows = [[a, 0], [b, 1]]
	for row in rows:
		var team = row[0]
		var y = at.y + 3 + row[1] * 19
		var nm = "?" if team == -1 else ucl.names[team]
		var col = DIM if team == -1 else WHITE
		if team != -1 and team == ucl.tTeam:
			col = GOLD
		if win != -1 and team != win:
			col = col.darkened(0.45)
		_label(page, nm, Vector2(at.x + 6, y), Vector2(w - 40, 18), fSmall, col)
		if s != null:
			var score = str(s[row[1]]) + ("p" if pens and team == win else "")
			_label(page, score, Vector2(at.x + w - 34, y), Vector2(30, 18), fSmall, col, Label.ALIGN_RIGHT)

# The next-match box with the right button: play, simulate a round, simulate to the end, or done.
func _nextBox(at, w):
	_rect(page, at, Vector2(w, 128 if w < 500 else 58), PANEL)
	var f = ucl.nextMatch()
	if ucl.champion != -1:
		var won = ucl.champion == ucl.tTeam
		_label(page, ("YOU WON THE CHAMPIONS LEAGUE!" if won else "Champions: " + ucl.names[ucl.champion]), at + Vector2(14, 8), Vector2(w - 28, 30), fBig, GOLD)
		_button(page, "new tournament", at + Vector2(14, 44) if w < 500 else Vector2(330, 512), Vector2(240, 52), "_newTournament", [], fMed)
		return
	if f.size() == 2:
		var label = ("Matchday " + str(ucl.matchday + 1)) if not ucl.knockoutStage else UCL.ROUND_NAMES[ucl.koRound]
		label += "  -  " + ("home" if f[0] == ucl.tTeam else "away")
		if ucl._twoLegged():
			label += "  -  " + ("1st leg" if ucl.koLeg == 1 else "2nd leg")
			if ucl.koLeg == 2 and ucl.firstLeg.size() == 2:
				label += " (1st leg " + ucl.names[f[1]] + " " + str(ucl.firstLeg[0]) + "-" + str(ucl.firstLeg[1]) + " " + ucl.names[f[0]] + ")"
		_label(page, label, at + Vector2(14, 6), Vector2(w - 28, 22), fMed, DIM)
		_label(page, ucl.names[f[0]] + "  vs  " + ucl.names[f[1]], at + Vector2(14, 28), Vector2(w - 28 if w < 500 else 560, 30), fBig, WHITE)
		var b = _button(page, "play match", at + Vector2(14, 66) if w < 500 else Vector2(210, 512), Vector2(220 if w < 500 else 190, 52), "_play", [], fBig)
		# Skip a match: simulated from the clubs' real strength like every other result.
		_button(page, "simulate", at + Vector2(244, 66) if w < 500 else Vector2(410, 512), Vector2(154 if w < 500 else 190, 52), "_simRound", [], fMed)
		b.grab_focus()
		return
	if ucl.playerOut:
		var msg = "Knocked out."
		if not ucl.knockoutStage or ucl.koResults.size() == 0:
			msg = "Out in the league phase (" + _ordinal(ucl.position(ucl.tTeam)) + ")."
		_label(page, msg, at + Vector2(14, 8), Vector2(w - 28, 30), fBig, Color(1.0, 0.6, 0.6))
		_button(page, "simulate to the final", at + Vector2(14, 44) if w < 500 else Vector2(330, 512), Vector2(270, 52), "_simEnd", [], fMed)
		return
	# Not in this round (e.g. the play-off when you finished top 8).
	_label(page, "You're through - " + UCL.ROUND_NAMES[ucl.koRound].to_lower() + " is played without you.", at + Vector2(14, 8), Vector2(w - 28, 30), fMed, WHITE)
	_button(page, "simulate round", at + Vector2(14, 44) if w < 500 else Vector2(330, 512), Vector2(240, 52), "_simRound", [], fMed)

# --- Buttons --------------------------------------------------------------------------------

func _play():
	if busy:
		return
	var f = ucl.nextMatch()
	if f.size() != 2:
		return
	busy = true
	Global.tType = 6
	Global.isPenalties = false
	Global.isT1Womens = false
	Global.isT2Womens = false
	Global.final = ucl.isFinal()
	Global.doShootout = ucl.knockoutStage
	Global.p1human = f[0] == ucl.tTeam
	Global.p2human = not Global.p1human
	# The Champions League is played 8v8.
	Global.setEightMode(true)
	Global.team1 = ucl.path(f[0])
	Global.team2 = ucl.path(f[1])
	Global._loadTeams(false, false)
	# Knockouts: strong clubs (and anyone in the final) get the sharpest AI. Only this match's copy
	# of the team changes, not the club's file.
	if ucl.knockoutStage:
		var ai = f[1] if f[0] == ucl.tTeam else f[0]
		if ucl.ratings[ai] >= UCL.SHARP_AI_RATING or ucl.isFinal():
			if ai == f[0]:
				Global.t1 = Global.t1.duplicate()
				Global.t1.level = 0.0
			else:
				Global.t2 = Global.t2.duplicate()
				Global.t2.level = 0.0
	# Quarter-finals and later: big-game players step up (this match's copy of the team only).
	if ucl.knockoutStage and ucl.koRound >= 2:
		Global.t1 = _bigGame(Global.t1)
		Global.t2 = _bigGame(Global.t2)
	Global.toLoad = 1
	Global.stadium = 3 - int(Global.t1.level)
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Game.tscn")

# Save button: writes the tournament now (it also saves itself after every match).
func _saveButton(at, size):
	saveBtn = _button(page, "save", at, size, "_save", [], fMed)

func _save():
	ucl.saveState()
	if saveBtn and is_instance_valid(saveBtn):
		saveBtn.text = "saved!"

func _bigGame(td):
	var copy = null
	for i in range(12):
		var key = "player" + str(i)
		var pp = td.get(key)
		if typeof(pp) != TYPE_DICTIONARY or not UCL.BIG_GAME_PLAYERS.has(pp.get("name", "")):
			continue
		if copy == null:
			copy = td.duplicate()
		var boosted = pp.duplicate()
		var plus = UCL.BIG_GAME_PLAYERS[pp["name"]]
		for k in plus:
			boosted[k] = min(float(boosted.get(k, 5.0)) + plus[k], 10.0)
		copy.set(key, boosted)
	return copy if copy != null else td

func _simRound():
	ucl.simulateRound()
	_show()

func _simEnd():
	ucl.simulateToEnd()
	showTable = false
	_show()

func _toggleTable():
	showTable = not showTable
	_show()

func _newTournament():
	ucl = null
	Global.tournament = null
	showTable = false
	_show()

func _menu():
	if busy:
		return
	busy = true
	trans._wipeOff()
	yield(trans.tween, "tween_completed")
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")

# --- Helpers --------------------------------------------------------------------------------

func _title(t):
	_label(page, t, Vector2(18, 6), Vector2(700, 46), fTitle, GOLD)

func _font(p, size):
	var f = DynamicFont.new()
	f.font_data = load(p)
	f.size = size
	f.use_filter = true
	return f

func _rect(parent, at, size, col):
	var r = ColorRect.new()
	r.rect_position = at
	r.rect_size = size
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _label(parent, t, at, size, font, col, align = Label.ALIGN_LEFT):
	var l = Label.new()
	l.text = t
	l.rect_position = at
	l.rect_size = size
	l.clip_text = true
	l.align = align
	l.add_font_override("font", font)
	l.add_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _button(parent, t, at, size, method, args, font):
	var b = Button.new()
	b.text = t
	b.rect_position = at
	b.rect_min_size = size
	b.rect_size = size
	b.clip_text = true
	b.add_font_override("font", font)
	var _c = b.connect("pressed", self, method, args)
	parent.add_child(b)
	return b

func _ordinal(n):
	var s = "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1:
				s = "st"
			2:
				s = "nd"
			3:
				s = "rd"
	return str(n) + s
