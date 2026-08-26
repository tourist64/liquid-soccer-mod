extends Control


var screen = "nickname"
var nickname = ""
var busy = false
var last_rooms = ""
var waiting_for_connection = false
var poll_elapsed = 0.0


func _ready():
	_show_screen("NicknameScreen")
	$Screens/NicknameScreen/Nickname.grab_focus()
	if OS.has_feature("HTML5"):
		JavaScript.eval("window.slsMultiplayerEnsure && window.slsMultiplayerEnsure()", true)
	else:
		_set_status("O multiplayer funciona na versão publicada no navegador.")


func _process(delta):
	if not OS.has_feature("HTML5") or not waiting_for_connection:
		return
	poll_elapsed += delta
	if poll_elapsed < 0.25:
		return
	poll_elapsed = 0.0

	var raw_state = JavaScript.eval("window.slsMultiplayerState ? window.slsMultiplayerState() : '{}'", true)
	if typeof(raw_state) != TYPE_STRING:
		return
	var state = parse_json(raw_state)
	if typeof(state) != TYPE_DICTIONARY:
		return

	var bridge_busy = bool(state.get("busy", false))
	var connected = bool(state.get("connected", false))
	var host = bool(state.get("host", false))
	busy = bridge_busy
	$Screens/CreateScreen/CreateConfirm.disabled = bridge_busy or (host and connected)
	$Screens/CreateScreen/CreateConfirm.text = "Conectando..." if bridge_busy else ("Sala criada" if host and connected else "Criar sala")
	$Screens/CreateScreen/Start.visible = host and connected
	$Screens/CreateScreen/Start.disabled = not connected
	$Screens/RoomsScreen/JoinSelected.disabled = bool(state.get("busy", false))
	$Screens/RoomsScreen/JoinSelected.text = "Conectando..." if bridge_busy else "Entrar na sala"
	$Screens/RoomsScreen/Refresh.disabled = bool(state.get("rooms_busy", false))

	var status = str(state.get("status", ""))
	if status != "":
		_set_status(status)
	if screen == "rooms":
		_update_rooms(state.get("rooms", []))
	if bool(state.get("started", false)):
		waiting_for_connection = false
		_start_match()


func _show_screen(name):
	$Screens/NicknameScreen.visible = name == "NicknameScreen"
	$Screens/ChoiceScreen.visible = name == "ChoiceScreen"
	$Screens/CreateScreen.visible = name == "CreateScreen"
	$Screens/RoomsScreen.visible = name == "RoomsScreen"
	screen = name.replace("Screen", "").to_lower()


func _set_status(message):
	$Status.text = message


func _js_string(value):
	return to_json(str(value))


func _on_Continue_pressed():
	nickname = $Screens/NicknameScreen/Nickname.text.strip_edges()
	if nickname == "":
		_set_status("Digite um nickname para continuar.")
		$Screens/NicknameScreen/Nickname.grab_focus()
		return

	_show_screen("ChoiceScreen")
	_set_status("Nickname salvo. Escolha criar uma sala ou entrar em uma existente.")


func _on_Create_choice_pressed():
	_show_screen("CreateScreen")
	$Screens/CreateScreen/Room.grab_focus()
	_set_status("Defina o nome e a senha da sala.")


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
	if signature == last_rooms:
		return
	last_rooms = signature
	$Screens/RoomsScreen/RoomList.clear()
	for room in rooms:
		if typeof(room) == TYPE_DICTIONARY:
			var index = $Screens/RoomsScreen/RoomList.get_item_count()
			$Screens/RoomsScreen/RoomList.add_item(str(room.get("name", "Sala")))
			$Screens/RoomsScreen/RoomList.set_item_metadata(index, str(room.get("id", "")))
	if rooms.size() == 0:
		_set_status("Nenhuma sala encontrada. Crie uma sala ou atualize a lista.")
	else:
		_set_status("Selecione uma sala e informe a senha para entrar.")


func _on_Create_confirm_pressed():
	if busy:
		return
	var room = $Screens/CreateScreen/Room.text.strip_edges()
	var password = $Screens/CreateScreen/Password.text
	if room == "" or password == "":
		_set_status("Preencha o nome e a senha da sala.")
		return
	busy = true
	waiting_for_connection = true
	poll_elapsed = 0.0
	$Screens/CreateScreen/CreateConfirm.disabled = true
	$Screens/CreateScreen/CreateConfirm.text = "Conectando..."
	_set_status("Conectando à sala...")
	if OS.has_feature("HTML5"):
		var call = "window.slsMultiplayerCreate(%s,%s,%s)" % [_js_string(nickname), _js_string(room), _js_string(password)]
		JavaScript.eval(call, true)


func _on_Join_selected_pressed():
	if busy:
		return
	var selected = $Screens/RoomsScreen/RoomList.get_selected_items()
	if selected.size() == 0:
		_set_status("Selecione uma sala primeiro.")
		return
	var password = $Screens/RoomsScreen/Password.text
	if password == "":
		_set_status("Digite a senha da sala.")
		return
	var room_id = str($Screens/RoomsScreen/RoomList.get_item_metadata(selected[0]))
	busy = true
	waiting_for_connection = true
	poll_elapsed = 0.0
	$Screens/RoomsScreen/JoinSelected.disabled = true
	$Screens/RoomsScreen/JoinSelected.text = "Conectando..."
	_set_status("Conectando à sala...")
	if OS.has_feature("HTML5"):
		var call = "window.slsMultiplayerJoin(%s,%s,%s)" % [_js_string(nickname), _js_string(room_id), _js_string(password)]
		JavaScript.eval(call, true)


func _on_Start_pressed():
	if OS.has_feature("HTML5"):
		_set_status("Iniciando partida...")
		JavaScript.eval("window.slsMultiplayerStart && window.slsMultiplayerStart()", true)


func _on_Back_pressed():
	waiting_for_connection = false
	busy = false
	poll_elapsed = 0.0
	if screen == "nickname":
		if OS.has_feature("HTML5"):
			JavaScript.eval("window.slsMultiplayerLeave && window.slsMultiplayerLeave()", true)
		get_tree().change_scene("res://Scenes/Menu.tscn")
	elif screen == "choice":
		_show_screen("NicknameScreen")
		$Screens/NicknameScreen/Nickname.grab_focus()
	else:
		if OS.has_feature("HTML5"):
			JavaScript.eval("window.slsMultiplayerLeave && window.slsMultiplayerLeave()", true)
		_show_screen("ChoiceScreen")


func _start_match():
	Global.multiplayer_mode = true
	Global.p1human = true
	Global.p2human = true
	Global.setupMultiplayerKeys()
	Global.toLoad = 2
	Global.isPenalties = false
	get_tree().change_scene("res://Scenes/Loading.tscn")
