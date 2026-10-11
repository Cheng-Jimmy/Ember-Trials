class_name BattleTheme
extends RefCounted

const INK := Color("111b28")
const PANEL := Color("182536")
const GOLD := Color("d9b879")
const TEXT := Color("e8e7e1")
const MUTED := Color("91a3b5")
const RED := Color("dc786a")
const BLUE := Color("69b5d4")
const VIOLET := Color("b49bde")
const GREEN := Color("8bc992")

static func box(color: Color = PANEL, border: Color = Color("344355"), radius: int = 12, width: int = 1) -> StyleBoxFlat:
 var result := StyleBoxFlat.new()
 result.bg_color = color
 result.border_color = border
 result.set_border_width_all(maxi(2, width))
 result.set_corner_radius_all(0)
 result.content_margin_left = 16
 result.content_margin_right = 16
 result.content_margin_top = 6
 result.shadow_color = Color(0, 0, 0, 0.28)
 result.shadow_size = 4
 result.shadow_offset = Vector2(0, 4)
 result.content_margin_bottom = 10
 return result

static func make_theme() -> Theme:
 var result := Theme.new()
 var font: FontFile = load("res://assets/fonts/FusionPixel.ttf")
 font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
 font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
 result.default_font = font
 result.default_font_size = 24
 result.set_font_size("font_size", "TooltipLabel", 24)
 result.set_stylebox("panel", "TooltipPanel", box(INK, GOLD))
 result.set_color("font_color", "Label", TEXT)
 result.set_color("font_color", "Button", TEXT)
 result.set_color("font_hover_color", "Button", Color.WHITE)
 result.set_color("font_disabled_color", "Button", MUTED.darkened(0.35))
 result.set_stylebox("normal", "Button", box(PANEL, Color("526077")))
 result.set_stylebox("hover", "Button", box(Color("293c4e"), GOLD))
 result.set_stylebox("pressed", "Button", box(Color("344557"), GOLD))
 result.set_stylebox("disabled", "Button", box(Color("17202c"), Color("2a3542")))
 result.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), GOLD, 12, 2))
 return result

