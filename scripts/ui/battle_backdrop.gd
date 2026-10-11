class_name BattleBackdrop
extends Control
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO, size), Color("101b28"))
 for y in range(0, 640, 32):
  for x in range(300, 1300, 64):
   var shift := 32 if (y / 32) % 2 else 0
   var color := Color("192b39") if (x / 64 + y / 32) % 4 else Color("203341")
   draw_rect(Rect2(x + shift, y, 61, 29), color)
   draw_rect(Rect2(x+shift+3,y+2,53,2),color.lightened(0.035))
   if (x/64+y/32)%9==0:draw_rect(Rect2(x+shift+20,y+6,2,13),color.darkened(0.2))
 for x in [312, 1250]:
  draw_rect(Rect2(x, 0, 38, 620), Color("304653"))
  for y in range(0, 620, 36): draw_rect(Rect2(x, y, 38, 4), Color("172934"))
 for x in [395, 1170]:
  draw_rect(Rect2(x, 190, 12, 55), Color("754d39"))
  draw_rect(Rect2(x - 6, 164, 24, 32), Color("d78647"))
  draw_rect(Rect2(x, 158, 12, 25), Color("edc278"))
 for y in range(640, 900, 32):
  for x in range(300, 1300, 64): draw_rect(Rect2(x, y, 61, 29), Color("263a46") if (x/64+y/32)%2 else Color("20323f"))
 draw_rect(Rect2(305, 624, 990, 5), Color("bb9f68"))
