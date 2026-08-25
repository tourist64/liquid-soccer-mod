extends Node


func pointToFrame( var p, var o, var f):
	
	var r = f.cross(Vector3.UP)
	return (p.x * r + p.y * Vector3.UP + p.z * f) + o
func pointToFrameAxis( var p, var o, var f, var r):
	
	return Vector3((p.dot( - r)), (p.dot(Vector3.UP)), (p.dot(f))) + o
func pointToTransform( var p, var t):
	return t.xform_inv(p)
	

func seePass( var o, var pd, var c):
	var dp = c - o
	var rt = - pd.cross(Vector3.UP)
	return Vector2(sign(dp.dot(rt)), sign(dp.dot(pd)))

func pointToLine( var A, var B, var P, var clmp):
	var AP = P - A
	var AB = B - A
	var abl = AB.length_squared()
	if abl < 0.1:
		return B
	
	var ABP = AP.dot(AB)
	var d = ABP / abl
	
	d = clamp(d, 0.0, clmp)
	return A + AB * d
	
func biLerp( var v0, var v1, var v2, var v3, ss: float, tt: float):
	
	
	
	
	var x = lerp(v0, v1, ss)
	var y = lerp(v2, v3, ss)
	return lerp(y, x, tt)
