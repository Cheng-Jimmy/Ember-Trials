class_name CardView
extends Button
signal selected(card: CardInstance)
var card: CardInstance
var card_size := Vector2(220, 332)
var _accent: Color
var _hover_tween: Tween
var compact := false
var hover_scale := 1.2
var description_label: Label
func setup(instance: CardInstance, small: bool = false) -> void:
 card = instance
 compact = small
 card_size = Vector2(170, 238) if compact else Vector2(220, 332)
 custom_minimum_size = card_size
 size = card_size
 pivot_offset = Vector2(card_size.x / 2, card_size.y)
 _accent = [BattleTheme.RED, BattleTheme.BLUE, BattleTheme.VIOLET][card.data.card_type]
 if card.data.tags.has("COUNTER"): _accent = BattleTheme.GOLD
 add_theme_stylebox_override("normal", BattleTheme.box(Color("182636"), _accent.darkened(0.1), 0, 3))
 add_theme_stylebox_override("hover", BattleTheme.box(Color("25384a"), _accent.lightened(0.2), 0, 4))
 add_theme_stylebox_override("pressed", BattleTheme.box(Color("304252"), BattleTheme.TEXT, 0, 4))
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 tooltip_text = card.data.display_name + "\n" + card.data.description
 _label(str(card.data.energy_cost),Vector2(8,6),Vector2(38,42),36 if not compact else 24,BattleTheme.TEXT,HORIZONTAL_ALIGNMENT_CENTER)
 _label(card.data.display_name.split(" / ")[0],Vector2(55,12),Vector2(card_size.x-65,32),24 if not compact else 20,BattleTheme.TEXT)
 var category: String = ["攻击","防御","技能"][card.data.card_type]
 if card.data.tags.has("COUNTER"): category = "技能 · 反击"
 if card.data.tags.has("FIELD"): category = "技能 · 场地"
 _label(category,Vector2(12,117 if not compact else 91),Vector2(card_size.x-24,26),24 if not compact else 18,_accent,HORIZONTAL_ALIGNMENT_CENTER)
 var y := 153.0 if not compact else 121.0
 description_label = _label(card.data.description.replace(" ",""),Vector2(12,y),Vector2(card_size.x-24,card_size.y-y-14),24 if not compact else 18,BattleTheme.TEXT)
 description_label.clip_text = compact
 pressed.connect(func(): selected.emit(card))
 mouse_entered.connect(_hover.bind(true))
 mouse_exited.connect(_hover.bind(false))
 focus_entered.connect(_hover.bind(true))
 focus_exited.connect(_hover.bind(false))
func _label(value: String, point: Vector2, dimensions: Vector2, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 var label := Label.new()
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.text = value
 label.position = point
 label.size = dimensions
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 label.horizontal_alignment = alignment
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(label)
 return label
func _hover(active: bool) -> void:
 if _hover_tween: _hover_tween.kill()
 z_index = 20 if active else 0
 _hover_tween = create_tween()
 _hover_tween.tween_property(self,"scale",Vector2.ONE*(hover_scale if active else 1.0),0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
func _draw() -> void:
 if card == null: return
 draw_rect(Rect2(4,4,card_size.x-8,49),Color(_accent,0.12))
 draw_rect(Rect2(7,6,40,40),_accent.darkened(0.55))
 draw_rect(Rect2(7,46,40,3),_accent)
 for p in [Vector2(6,6),Vector2(card_size.x-10,6),Vector2(6,card_size.y-10),Vector2(card_size.x-10,card_size.y-10)]: draw_rect(Rect2(p,Vector2(4,4)),_accent)
 var center := Vector2(card_size.x/2,86 if not compact else 68)
 var unit := 5 if not compact else 4
 draw_rect(Rect2(center-Vector2(34,27),Vector2(68,54)),Color("101c2b"))
 var pattern: Array[String]=[".......XX","......XXX",".....XXX.","....XXX..",".X.XXX...",".XXXX....","..XX.....",".XX.X....","XX......."]
 if card.data.card_type == CardData.Type.DEFENSE: pattern=[".XXXXXXX.","XXXXXXXXX","XXXXXXXXX","XXXXXXXXX",".XXXXXXX.",".XXXXXXX.","..XXXXX..","...XXX...","....X...."]
 if card.data.card_type == CardData.Type.SKILL: pattern=["....X....","...XXX...","..X...X..",".X..X..X.","X..XXX..X",".X..X..X.","..X...X..","...XXX...","....X...."]
 if card.data.id in ["cinder","kindle"]: pattern=[".....X...","....XX...",".X..XXX..",".XX.XXXX.","XXXXXXXX.","XXX.XXXXX","XX...XXXX",".XX.XXXX.","..XXXXX.."]
 if card.data.tags.has("COUNTER"): pattern=["X.......X","XX.....XX",".XX...XX.","..XX.XX..","...XXX...","..XX.XX..",".XX...XX.","XX.....XX","X.......X"]
 if card.data.tags.has("FIELD"): pattern=["XX..X..XX","XXXXXXXXX",".XXXXXXX.",".XX.X.XX.",".XX.X.XX.",".XX...XX.",".XX...XX.",".XX...XX.","XXXXXXXXX"]
 if card.data.id == "shield_strike": pattern=[".XXXXXXX.","XXXXXXXXX","XX...XXXX","XX..XXXXX","XX.XXXXX.",".XXXXXXX.","..XXXXX..","...XXX...","....X...."]
 for y in pattern.size():
  for x in pattern[y].length():
   if pattern[y][x]=="X": draw_rect(Rect2(center-Vector2(4.5,4.5)*unit+Vector2(x,y)*unit,Vector2.ONE*unit),_accent if (x+y)%4 else BattleTheme.TEXT)
 draw_rect(Rect2(14,147 if not compact else 115,card_size.x-28,2),_accent.darkened(0.55))
