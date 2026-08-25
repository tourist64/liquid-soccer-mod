extends Node

var sdk_handle = null
var _cb_commercial_break
var _cb_reward_break
var _cb_shareable_url

signal commercial_break_done(response)
signal rewarded_break_done(response)
signal shareable_url_ready(url)


func _ready():
	if OS.has_feature("JavaScript") == false:
		return
		
	sdk_handle = JavaScript.get_interface("PokiSDK")
	_cb_commercial_break = JavaScript.create_callback(self, "on_commercial_break")
	_cb_reward_break = JavaScript.create_callback(self, "on_reward_break")
	_cb_shareable_url = JavaScript.create_callback(self, "on_shareable_url")
	
	
func gameplayStart():
	if not sdk_handle:
		return
	sdk_handle.gameplayStart()
	
func gameplayStop():
	if not sdk_handle:
		return
	sdk_handle.gameplayStop()
	
func commercialBreak():
	if not sdk_handle:
		print("no sdk handle!")
		return false
	sdk_handle.commercialBreak().then(_cb_commercial_break)
	
	
	
	return true
func on_commercial_break(args):
	print("commercial break call :", args)
	print(_cb_commercial_break)
		
	
	emit_signal("commercial_break_done", args[0])

func rewardedBreak():
	print("rewarded break")
	if not sdk_handle:
		print("no sdk")
		return false
	sdk_handle.rewardedBreak().then(_cb_reward_break)
	return true
func on_reward_break(args):
	print("reward break done", args)
	
	emit_signal("rewarded_break_done", args[0])
	
func shareableURL(obj: Dictionary):
	if not sdk_handle:
		return
	var params = JavaScript.create_object("Object")
	
	for key in obj.keys():
		params[key] = obj[key]
	sdk_handle.shareableURL(params).then(_cb_shareable_url)

func on_shareable_url(url):
	emit_signal("shareable_url_ready", url[0])
	
func isAdBlocked():
	if sdk_handle:
		var ret = sdk_handle.isAdBlocked()
		return ret
	return true
