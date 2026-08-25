extends Control


var match_started = false
var last_status = ""
var input_action_running = false


func _ready():
	$Card/Nickname.grab_focus()
	if OS.has_feature("HTML5"):
		JavaScript.eval("window.slsMultiplayerEnsure && window.slsMultiplayerEnsure()", true)
	else:
		$Card/Status.text = "O multiplayer funciona na versão publicada no navegador."
	last_status = $Card/Status.text


func _input(event):
	if not event is InputEventMouseButton or not event.pressed or event.button_index != BUTTON_LEFT:
		return
	if $Back.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		_on_Back_pressed()
	elif $Card/Create.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		_on_Create_pressed()
	elif $Card/Join.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		_on_Join_pressed()
	elif $Card/Start.get_global_rect().has_point(event.position) and $Card/Start.visible:
		get_viewport().set_input_as_handled()
		_on_Start_pressed()


func _process(_delta):
	if not OS.has_feature("HTML5") or match_started:
		return

	var raw_state = JavaScript.eval("window.slsMultiplayerState ? window.slsMultiplayerState() : '{}'", true)
	if typeof(raw_state) != TYPE_STRING:
		return

	var state = parse_json(raw_state)
	if typeof(state) != TYPE_DICTIONARY:
		return
	if not bool(state.get("busy", false)) and not bool(state.get("started", false)):
		input_action_running = false

	var status = str(state.get("status", ""))
	if status != last_status:
		$Card/Status.text = status
		last_status = status

	$Card/Create.disabled = bool(state.get("busy", false))
	$Card/Join.disabled = bool(state.get("busy", false))
	$Card/Start.visible = bool(state.get("host", false)) and bool(state.get("connected", false))
	$Card/Start.disabled = not bool(state.get("connected", false))

	if bool(state.get("started", false)):
		_start_match()


func _values_are_valid():
	var nickname = $Card/Nickname.text.strip_edges()
	var room = $Card/Room.text.strip_edges()
	var password = $Card/Password.text
	if nickname == "" or room == "" or password == "":
		$Card/Status.text = "Preencha nickname, sala e senha."
		return false
	return true


func _js_string(value):
	return to_json(str(value))


func _on_Create_pressed():
	if input_action_running:
		return
	if not _values_are_valid():
		return
	input_action_running = true
	$Card/Status.text = "Conectando à sala..."
	var call = "window.slsMultiplayerCreate(%s,%s,%s)" % [
		_js_string($Card/Nickname.text.strip_edges()),
		_js_string($Card/Room.text.strip_edges()),
		_js_string($Card/Password.text)
	]
	JavaScript.eval(call, true)


func _on_Join_pressed():
	if input_action_running:
		return
	if not _values_are_valid():
		return
	input_action_running = true
	$Card/Status.text = "Conectando à sala..."
	var call = "window.slsMultiplayerJoin(%s,%s,%s)" % [
		_js_string($Card/Nickname.text.strip_edges()),
		_js_string($Card/Room.text.strip_edges()),
		_js_string($Card/Password.text)
	]
	JavaScript.eval(call, true)


func _on_Start_pressed():
	if input_action_running:
		return
	input_action_running = true
	JavaScript.eval("window.slsMultiplayerStart && window.slsMultiplayerStart()", true)


func _on_Back_pressed():
	if input_action_running:
		return
	input_action_running = true
	if OS.has_feature("HTML5"):
		JavaScript.eval("window.slsMultiplayerLeave && window.slsMultiplayerLeave()", true)
	var _foo = get_tree().change_scene("res://Scenes/Menu.tscn")


func _start_match():
	match_started = true
	Global.multiplayer_mode = true
	Global.p1human = true
	Global.p2human = true
	Global.setupMultiplayerKeys()
	Global.toLoad = 2
	Global.isPenalties = false
	var _foo = get_tree().change_scene("res://Scenes/Loading.tscn")
