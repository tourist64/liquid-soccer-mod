extends ColorRect





var tween = null

func _ready():
	tween = $Tween
	
func _hideLoading():
	$Label.visible = false
func _showLoading():
	$Label.visible = true
func _wipeOnTex():
	get_material().set_shader_param("showTex", true)
	tween.interpolate_property(get_material(), "shader_param/cutoff", 0, 1, 0.33, 
								Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	
	_hideLoading()
func _wipeOffTex():
	get_material().set_shader_param("showTex", true)
	tween.interpolate_property(get_material(), "shader_param/cutoff", 1.0, 0.0, 0.33, 
								Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	_showLoading()
func _wipeOn():
	get_material().set_shader_param("showTex", false)
	tween.interpolate_property(get_material(), "shader_param/cutoff", 0, 1, 0.33, 
								Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	_hideLoading()
func _wipeOff():
	get_material().set_shader_param("showTex", false)
	tween.interpolate_property(get_material(), "shader_param/cutoff", 1, 0, 0.33, 
								Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	_showLoading()
	



