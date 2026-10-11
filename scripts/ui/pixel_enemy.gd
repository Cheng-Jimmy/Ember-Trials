class_name PixelEnemy
extends Control
var appearance := "slime"
var clock := 0.0
var hit_flash := 0.0
var recoil := 0.0
func _process(delta: float) -> void:
 clock += delta
 hit_flash=maxf(0,hit_flash-delta)
 recoil=move_toward(recoil,0,delta*60)
 queue_redraw()
func _draw() -> void:
 var unit := 7.0
 var offset := Vector2(40+floor(recoil), 9 + floor(sin(clock * 2.5) * 2) * 2)
 draw_rect(Rect2(42,174,205,12),Color(0.02,0.04,0.06,0.5))
 var outline := Color("0d1926")
 var main := Color("789b62")
 var light := Color("b1cd8c")
 if appearance == "raider": main = Color("98616a"); light = Color("d89b75")
 if appearance == "king": main = Color("a35445"); light = Color("e9b775")
 for y in 24:
  for x in 28:
   var filled := false
   if appearance == "slime": filled = (Vector2(x - 14, y - 14).length() < 10 and y > 3) or (y > 18 and x > 2 and x < 25)
   elif appearance == "golem": filled = (x > 5 and x < 22 and y > 3 and y < 20) or (y > 9 and y < 18 and x > 1 and x < 26) or (y >= 20 and ((x > 5 and x < 12) or (x > 16 and x < 23)))
   elif appearance == "raider": filled = (x > 8 and x < 19 and y > 2 and y < 21) or (x > 4 and x < 23 and y > 9 and y < 16) or (y > 16 and ((x > 6 and x < 12) or (x > 15 and x < 21)))
   else: filled = (x > 5 and x < 23 and y > 3 and y < 22) or (x > 1 and x < 27 and y > 10 and y < 18)
   if filled:
    var color := main if x < 19 else main.darkened(0.25)
    if y < 7 or x < 7: color = light
    if y in [7, 17] and x > 7 and x < 22: color = main.darkened(0.35)
    draw_rect(Rect2(offset + Vector2(x, y) * unit, Vector2.ONE * unit), Color("ffddbd") if hit_flash>0 else color)
 if appearance == "king":
  for x in range(7, 23):
   draw_rect(Rect2(offset + Vector2(x, 3) * unit, Vector2(unit, unit * (3 if x % 5 == 0 else 1))), Color("ebc76a"))
 for x in [11, 17]:
  draw_rect(Rect2(offset + Vector2(x, 9) * unit, Vector2(unit, unit * 2)), outline)
  draw_rect(Rect2(offset + Vector2(x, 9) * unit, Vector2(unit, unit)), Color("e8e5c2"))
 draw_rect(Rect2(offset + Vector2(13, 14) * unit, Vector2(unit * 3, unit)), outline)
 if appearance == "raider":
  draw_rect(Rect2(offset + Vector2(2, 11) * unit, Vector2(unit * 3, unit * 9)), Color("c4d4d3"))
  draw_rect(Rect2(offset + Vector2(23, 11) * unit, Vector2(unit * 3, unit * 9)), Color("c4d4d3"))

 if appearance in ["golem", "king"]:
  var plate := Color("3d6658") if appearance == "golem" else Color("633f3b")
  draw_rect(Rect2(offset+Vector2(8,8)*unit,Vector2(13,7)*unit),plate)
  draw_rect(Rect2(offset+Vector2(9,8)*unit,Vector2(11,1)*unit),light)
  for x in [11,17]:
   draw_rect(Rect2(offset+Vector2(x,10)*unit,Vector2(2,1)*unit),Color("f3d98f"))
   draw_rect(Rect2(offset+Vector2(x,11)*unit,Vector2(2,1)*unit),outline)
  draw_rect(Rect2(offset+Vector2(13,13)*unit,Vector2(4,1)*unit),outline)
  draw_rect(Rect2(offset+Vector2(11,16)*unit,Vector2(7,4)*unit),plate)
  draw_rect(Rect2(offset+Vector2(12,16)*unit,Vector2(5,1)*unit),light)
  if appearance == "king":
   draw_rect(Rect2(offset+Vector2(14,17)*unit,Vector2(2,2)*unit),Color("edb95f"))
   draw_rect(Rect2(offset+Vector2(3,14)*unit,Vector2(3,5)*unit),Color("b29676"))

 if appearance=="golem":
  for p in [Vector2(7,6),Vector2(20,6),Vector2(7,18),Vector2(20,18)]:
   draw_rect(Rect2(offset+p*unit,Vector2(1,1)*unit),Color("d3d7ad"))
  for p in [Vector2(5,3),Vector2(18,3),Vector2(23,10)]:
   draw_rect(Rect2(offset+p*unit,Vector2(2,1)*unit),Color("567f59"))
  draw_rect(Rect2(offset+Vector2(14,16)*unit,Vector2(1,4)*unit),Color("aac184"))
 if appearance=="king":
  draw_rect(Rect2(offset+Vector2(-1,7)*unit,Vector2(6,5)*unit),Color("382f36"))
  draw_rect(Rect2(offset+Vector2(-1,7)*unit,Vector2(6,1)*unit),Color("c6b291"))
  draw_rect(Rect2(offset+Vector2(2,12)*unit,Vector2(1,8)*unit),Color("a28266"))
  draw_rect(Rect2(offset+Vector2(12,5)*unit,Vector2(1,1)*unit),Color("efe2ad"))
 if appearance=="raider":
  draw_rect(Rect2(offset+Vector2(8,3)*unit,Vector2(12,3)*unit),Color("493f5b"))
  draw_rect(Rect2(offset+Vector2(9,13)*unit,Vector2(10,2)*unit),Color("493f5b"))
  draw_rect(Rect2(offset+Vector2(20,13)*unit,Vector2(2,5)*unit),Color("b47e8d"))
