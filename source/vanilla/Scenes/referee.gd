extends Spatial






var myref = null

func _ready():
	pass
func _setRef( var ref):
	myref = ref

func animDone():
	myref._animDone()
	
func cardDone():
	myref._cardDone()
func blowWhistle():
	myref._blowWhistleSound()



