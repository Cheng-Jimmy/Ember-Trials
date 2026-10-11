class_name BattleVisualFX
extends Control
var kind := "hit"
var tint := BattleTheme.RED
var age := 0.0
var duration := 0.55
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 z_index = 42
func _process(delta: float) -> void:
 age += delta
 if age >= duration: queue_free()
 else: queue_redraw()
func _draw() -> void:
 var p := age/duration
 var color := Color(tint,(1-p)*0.9)
 if kind == "burn":
  for i in 12:
   var x := (i%6)*14-35
   var y := -floorf(p*12)*4 + (i/6)*18
   draw_rect(Rect2(x,y,8,12),color)
   draw_rect(Rect2(x+2,y-4,4,6),Color(BattleTheme.GOLD,(1-p)*0.8))
 elif kind == "shield":
  var r := 22+floorf(p*6)*4
  for pos in [Vector2(-r,-r),Vector2(r-12,-r),Vector2(-r,r-4),Vector2(r-12,r-4)]:
   draw_rect(Rect2(pos,Vector2(12,4)),color)
  draw_rect(Rect2(-r,-r,4,2*r),color)
  draw_rect(Rect2(r-4,-r,4,2*r),color)
 elif kind == "equipment":
  for i in 6:
   var d := Vector2.RIGHT.rotated(i*TAU/6)*floorf(p*12)*4
   draw_rect(Rect2(d-Vector2(3,3),Vector2(6,6)),color)
 else:
  for i in 7:
   var d := Vector2.RIGHT.rotated(i*TAU/7)*floorf(p*14)*4
   draw_rect(Rect2(d-Vector2(4,4),Vector2(8,8)),color)
  if p<0.45:
   for i in 10:
    draw_rect(Rect2(-32+i*6,26-i*6,8,4),color)
    if kind == "counter": draw_rect(Rect2(-32+i*6,-26+i*6,8,4),color)

