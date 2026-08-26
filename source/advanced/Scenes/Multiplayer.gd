extends Control


var match_started = false
var last_status = ""
var input_action_running = false
var current_screen = "nickname"
var nickname = ""
var selected_room_id = ""
var room_signature = ""


func _ready():
	_show_screen("NicknameScreen")
	$Screens/NicknameScreen/Nickname.grab_focus()
	if OS.has_feature("HTML5"):
		JavaScript.eval("window.slsMultiplayerEnsure && window.slsMultiplayerEnsure()", true)
	else:
		$Status.text = "O multiplayer funciona na versão publicada no navegador."
	last_status = $Status.text


func _process(_delta):
	if not OS.has_feature("HTML5") or match_started or (current_screen != "create" and current_screen != "rooms"):
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
		$Status.text = status
		last_status = status

	$Screens/CreateScreen/CreateConfirm.disabled = bool(state.get("busy", false))
	$Screens/CreateScreen/CreateConfirm.visible = not bool(state.get("host", false))
	$Screens/CreateScreen/Start.visible = bool(state.get("host", false)) and bool(state.get("connected", false))
	$Screens/CreateScreen/Start.disabled = not bool(state.get("connected", false))
	$Screens/RoomsScreen/JoinSelected.disabled = bool(state.get("busy", false))
	$Screens/RoomsScreen/Refresh.disabled = bool(state.get("rooms_busy", false))
	if current_screen == "rooms":
		_update_rooms(state.get("rooms", []))

	if bool(state.get("started", false)):
		_start_match()


func _show_screen(screen_name):
	$Screens/NicknameScreen.visible = screen_name == "NicknameScreen"
	$Screens/ChoiceScreen.visible = screen_name == "ChoiceScreen"
	$Screens/CreateScreen.visible = screen_name == "CreateScreen"
	$Screens/RoomsScreen.visible = screen_name == "RoomsScreen"
	current_screen = screen_name.replace("Screen", "").to_lower()


func _set_status(message):
	$Status.text = message
	last_status = message


func _js_string(value):
	return to_json(str(value))


func _on_Continue_pressed():
	nickname = $Screens/NicknameScreen/Nickname.text.strip_edges()
	if nickname == "":
		_set_status("Digite um nickname para continuar.")
		return
	_show_screen("ChoiceScreen")
	_set_status("Escolha se deseja criar uma sala ou entrar em uma sala existente.")


func _on_Create_choice_pressed():
	_show_screen("CreateScreen")
	$Screens/CreateScreen/Room.grab_focus()
	_set_status("Defina o nome e a senha da sua sala.")


func _on_Enter_choice_pressed():
	_show_screen("RoomsScreen")
	_set_status("Procurando salas disponíveis...")
	if OS.has_feature("HTML5"):
		JavaScript.eval("window.slsMultiplayerListRooms && window.slsMultiplayerListRooms()", true)


func _on_Refresh_pressed():
	_set_status("Atualizando salas disponíveis...")
	if OS.has_feature("HTML5"):
		JavaScript.eval("window.slsMultiplayerListRooms && window.slsMultiplayerListRooms()", true)


func _update_rooms(rooms):
	if typeof(rooms) != TYPE_ARRAY:
		return
	var signature = to_json(rooms)
	if signature == room_signature:
		return
	room_signature = signature
	$Screens/RoomsScreen/RoomList.clear()
	for room in rooms:
		if typeof(room) == TYPE_DICTIONARY:
			var index = $Screens/RoomsScreen/RoomList.get_item_count()
			$Screens/RoomsScreen/RoomList.add_item(str(room.get("name", "Sala")))
			$Screens/RoomsScreen/RoomList.set_item_metadata(index, str(room.get("id", "")))
	if rooms.size() == 0:
		_set_status("Nenhuma sala encontrada. Crie uma sala ou atualize a lista.")
	else:
		_set_status("Selecione uma sala e digite a senha para entrar.")


func _on_Join_selected_pressed():
	if input_action_running:
		return
	var selected = $Screens/RoomsScreen/RoomList.get_selected_items()
	if selected.size() == 0:
		_set_status("Selecione uma sala primeiro.")
		return
	var password = $Screens/RoomsScreen/Password.text
	if password == "":
		_set_status("Digite a senha da sala.")
		return
	selected_room_id = str($Screens/RoomsScreen/RoomList.get_item_metadata(selected[0]))
	input_action_running = true
	_set_status("Conectando à sala...")
	var call = "window.slsMultiplayerJoin(%s,%s,%s)" % [
		_js_string(nickname), _js_string(selected_room_id), _js_string(password)
	]
	JavaScript.eval(call, true)


func _on_Create_confirm_pressed():
	if input_action_running:
		return
	var room = $Screens/CreateScreen/Room.text.strip_edges()
	var password = $Screens/CreateScreen/Password.text
	if room == "" or password == "":
		_set_status("Preencha o nome e a senha da sala.")
		return
	input_action_running = true
	_set_status("Conectando à sala...")
	var call = "window.slsMultiplayerCreate(%s,%s,%s)" % [
		_js_string(nickname), _js_string(room), _js_string(password)
	]
	JavaScript.eval(call, true)


func _on_Start_pressed():
	if input_action_running:
		return
	input_action_running = true
	JavaScript.eval("window.slsMultiplayerStart && window.slsMultiplayerStart()", true)


func _on_Back_pressed():
	if current_screen == "nickname":
		if OS.has_feature("HTML5"):
			JavaScript.eval("window.slsMultiplayerLeave && window.slsMultiplayerLeave()", true)
		input_action_running = false
		get_tree().change_scene("res://Scenes/Menu.tscn")
	elif current_screen == "choice":
		_show_screen("NicknameScreen")
		$Screens/NicknameScreen/Nickname.grab_focus()
	elif current_screen == "create":
		if OS.has_feature("HTML5"):
			JavaScript.eval("window.slsMultiplayerLeave && window.slsMultiplayerLeave()", true)
		_show_screen("ChoiceScreen")
	else:
		if OS.has_feature("HTML5"):
			JavaScript.eval("window.slsMultiplayerLeave && window.slsMultiplayerLeave()", true)
		_show_screen("ChoiceScreen")


func _start_match():
	match_started = true
	Global.multiplayer_mode = true
	Global.p1human = true
	Global.p2human = true
	Global.setupMultiplayerKeys()
	Global.toLoad = 2
	Global.isPenalties = false
	get_tree().change_scene("res://Scenes/Loading.tscn")
