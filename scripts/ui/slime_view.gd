class_name SlimeView
extends Control

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 draw_set_transform(Vector2(130, 167), 0, Vector2(1, 0.20))
 draw_circle(Vector2.ZERO, 116, Color(0.02, 0.05, 0.04, 0.65))
 draw_set_transform(Vector2.ZERO)
 var shape := PackedVector2Array([Vector2(28, 158), Vector2(31, 136), Vector2(46, 119), Vector2(50, 85), Vector2(67, 52), Vector2(94, 30), Vector2(130, 21), Vector2(162, 31), Vector2(190, 57), Vector2(207, 100), Vector2(211, 128), Vector2(233, 151), Vector2(221, 166), Vector2(184, 175), Vector2(75, 176)])
 draw_colored_polygon(shape, Color("477f58"))
 draw_polyline(shape, Color("9ac27b"), 3.0, true)
 draw_circle(Vector2(126, 99), 63, Color("609c68"))
 draw_circle(Vector2(105, 68), 21, Color("90bf81"))
 draw_circle(Vector2(96, 58), 8, Color("d1e6a6"))
 draw_style_box(BattleTheme.box(Color("122d2a"), Color("122d2a"), 5, 0), Rect2(95, 108, 10, 24))
 draw_style_box(BattleTheme.box(Color("122d2a"), Color("122d2a"), 5, 0), Rect2(154, 108, 10, 24))
 draw_circle(Vector2(98, 110), 2, Color.WHITE)
 draw_circle(Vector2(157, 110), 2, Color.WHITE)
 draw_arc(Vector2(131, 132), 8, 0.15, PI - 0.15, 12, Color("23483b"), 2, true)

