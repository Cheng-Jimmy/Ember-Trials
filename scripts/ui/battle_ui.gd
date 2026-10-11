class_name BattleUI
extends Control

@onready var battle: BattleManager = $BattleManager
signal completed(won: bool)
var campaign_mode := false
var auto_start := true
var enemy_name: Label
var enemy_art: PixelEnemy
var sound: AudioStreamPlayer
var help_overlay: Control
var equipment_tiles: Array[Panel] = []
var _views: Dictionary = {}
var _last_block := 0
var _last_turn := 0
var _last_attack_count := 0
var _popup_sequence := 0
var _popup_time := 0
var _popup_elapsed := 1.0
var card_transition_count := 0
var player_status: Label
var enemy_status: Label
var enemy_hp_bar: ProgressBar
var intent: Label
var turn_label: Label
var energy_label: Label
var pile_labels: Array[Label] = []
var card_layer: Control
var extra_row: HBoxContainer
var extra_scroll: ScrollContainer
var counter_label: Label
var field_label: Label
var adjust_button: Button
var end_button: Button
var skip_button: Button
var cancel_button: Button
var prompt_label: Label
var log_label: Label
var focus_label: Label
var toast: Label
var modal: Control
var modal_title: Label
var modal_body: Label
var modal_primary: Button
var modal_secondary: Button
var debug_panel: BattleDebugPanel
var toast_timer: Timer
var slot_labels: Array[Label] = []

func _ready() -> void:
 theme = BattleTheme.make_theme()
 _build_layout()
 battle.changed.connect(refresh)
 battle.feedback.connect(_show_feedback)
 battle.visual_event.connect(_visual_feedback)
 sound = AudioStreamPlayer.new()
 sound.volume_db = -12
 add_child(sound)
 if auto_start: battle.start_battle()
 else: refresh()

func _build_layout() -> void:
 var background := BattleBackdrop.new()
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 _panel(self,Rect2(24,24,276,128))
 _label(self,"勇者",Rect2(44,39,236,30),24,BattleTheme.GOLD)
 player_status=_label(self,"",Rect2(44,78,240,70),24)
 _panel(self,Rect2(24,174,276,276))
 _label(self,"装备",Rect2(44,188,236,32),24,BattleTheme.GOLD)
 var item_paths: Array[String]=["ember_sword","leather_armor","ruby_ring"]
 for index in 3:
  var item: EquipmentData = battle.configured_equipment[index] if battle.use_custom_equipment and index<battle.configured_equipment.size() else load("res://resources/equipment/%s.tres"%item_paths[index])
  var y:=230+index*70
  var tile:=_panel(self,Rect2(38,y,248,62),Color("1d2d3a"),Color("3b5262"))
  tile.mouse_filter=Control.MOUSE_FILTER_PASS
  tile.tooltip_text=item.display_name+"\n"+item.description
  equipment_tiles.append(tile)
  _label(self,["刃","甲","戒"][index],Rect2(44,y+14,32,32),24,BattleTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
  _label(self,item.display_name,Rect2(88,y+5,186,28),24)
  var summary:=_equipment_brief(item)
  var detail:=_label(self,summary,Rect2(88,y+33,186,26),18,BattleTheme.MUTED)
  detail.clip_text=true
 _panel(self,Rect2(24,470,276,126))
 _label(self,"战斗记录",Rect2(44,483,236,28),22,BattleTheme.GOLD)
 log_label=_label(self,"",Rect2(44,520,238,29),18,BattleTheme.MUTED)
 log_label.clip_text=true
 _label(self,"EMBER  /  试炼场",Rect2(510,48,580,26),20,BattleTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
 enemy_name=_label(self,"",Rect2(520,83,560,43),36,BattleTheme.TEXT,HORIZONTAL_ALIGNMENT_CENTER)
 enemy_hp_bar=ProgressBar.new()
 enemy_hp_bar.position=Vector2(550,138)
 enemy_hp_bar.size=Vector2(500,28)
 enemy_hp_bar.show_percentage=false
 enemy_hp_bar.add_theme_stylebox_override("background",BattleTheme.box(Color("382b30"),Color("8e665d")))
 enemy_hp_bar.add_theme_stylebox_override("fill",BattleTheme.box(Color("c77465"),Color("e8a184")))
 add_child(enemy_hp_bar)
 enemy_status=_label(self,"",Rect2(495,178,610,32),24,BattleTheme.TEXT,HORIZONTAL_ALIGNMENT_CENTER)
 _panel(self,Rect2(554,220,492,85),Color("152a37"),Color("66858b"))
 intent=_label(self,"",Rect2(566,232,468,67),24,BattleTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
 enemy_art=PixelEnemy.new()
 enemy_art.position=Vector2(652,310)
 enemy_art.size=Vector2(300,186)
 add_child(enemy_art)
 _panel(self,Rect2(1320,24,256,94))
 turn_label=_label(self,"",Rect2(1332,50,232,48),28,BattleTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
 _panel(self,Rect2(1320,138,256,102),Color("292a30"),BattleTheme.GOLD.darkened(0.45))
 counter_label=_label(self,"",Rect2(1334,150,230,80),24,BattleTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
 _panel(self,Rect2(1320,256,256,102),Color("1d3033"),BattleTheme.GREEN.darkened(0.45))
 field_label=_label(self,"",Rect2(1334,267,230,83),24,BattleTheme.GREEN,HORIZONTAL_ALIGNMENT_CENTER)
 _button(self,"规则帮助  [?]",Rect2(1320,380,256,42),_toggle_help)
 _button(self,"战术日志  [F3]",Rect2(1320,437,256,43),_toggle_debug)
 for index in 3:
  var y:=507+index*106
  _panel(self,Rect2(1320,y,256,91))
  _label(self,["抽牌堆","弃牌堆","失效区"][index],Rect2(1338,y+24,150,35),24)
  pile_labels.append(_label(self,"",Rect2(1492,y+18,65,50),34,BattleTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER))
 end_button=_button(self,"结束回合  →",Rect2(1320,839,256,44),battle.end_turn)
 _panel(self,Rect2(24,644,276,113),Color("183344"),BattleTheme.BLUE)
 _label(self,"能量",Rect2(44,650,100,31),24,BattleTheme.BLUE)
 energy_label=_label(self,"",Rect2(120,674,158,64),44,BattleTheme.TEXT,HORIZONTAL_ALIGNMENT_CENTER)
 adjust_button=_button(self,"调整 · 免费",Rect2(24,780,276,60),battle.begin_adjust)
 _label(self,"每回合一次",Rect2(44,850,236,28),20,BattleTheme.MUTED,HORIZONTAL_ALIGNMENT_CENTER)
 focus_label=_label(self,"",Rect2(355,326,230,80),24,BattleTheme.VIOLET)
 _label(self,"额外手牌",Rect2(1060,195,240,30),20,BattleTheme.MUTED)
 extra_scroll=ScrollContainer.new()
 extra_scroll.position=Vector2(1054,228)
 extra_scroll.size=Vector2(254,316)
 extra_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 add_child(extra_scroll)
 var margin:=MarginContainer.new()
 margin.add_theme_constant_override("margin_left",20)
 margin.add_theme_constant_override("margin_right",20)
 margin.add_theme_constant_override("margin_top",52)
 margin.add_theme_constant_override("margin_bottom",4)
 extra_scroll.add_child(margin)
 extra_row=HBoxContainer.new()
 extra_row.add_theme_constant_override("separation",12)
 margin.add_child(extra_row)
 prompt_label=_label(self,"",Rect2(44,564,238,28),20,BattleTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER)
 skip_button=_button(self,"不保留",Rect2(1320,380,256,42),func():battle.choose_retain(null))
 cancel_button=_button(self,"取消",Rect2(1320,437,256,43),battle.cancel_selection)
 skip_button.z_index=30
 cancel_button.z_index=30
 card_layer=Control.new()
 card_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(card_layer)
 for slot in 4:
  var point:=_slot_position(slot)
  _panel(card_layer,Rect2(point,Vector2(220,332)),Color("131f2c"),Color("3a4e5c"))
  _label(card_layer,"空槽",Rect2(point+Vector2(0,125),Vector2(220,35)),24,BattleTheme.MUTED.darkened(0.2),HORIZONTAL_ALIGNMENT_CENTER)
  slot_labels.append(_label(self,"",Rect2(point-Vector2(0,28),Vector2(220,26)),20,BattleTheme.MUTED,HORIZONTAL_ALIGNMENT_CENTER))
 toast=_label(self,"",Rect2(460,430,680,52),28,Color("ffbd91"),HORIZONTAL_ALIGNMENT_CENTER)
 toast.z_index=35
 toast_timer=Timer.new()
 toast_timer.one_shot=true
 toast_timer.wait_time=2.5
 toast_timer.timeout.connect(func():toast.text="")
 add_child(toast_timer)
 _build_modal()
 _build_help()
 debug_panel=BattleDebugPanel.new()
 debug_panel.position=Vector2(320,28)
 debug_panel.size=Vector2(680,850)
 debug_panel.z_index=100
 debug_panel.visible=false
 add_child(debug_panel)

func _build_modal() -> void:
 modal = Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.z_index = 50
 add_child(modal)
 var shade := ColorRect.new()
 shade.color = Color(0.025, 0.04, 0.07, 0.84)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(shade)
 _panel(modal, Rect2(474, 280, 652, 338), Color("1b2a39"), BattleTheme.GOLD)
 modal_title = _label(modal, "", Rect2(510, 305, 580, 57), 36, BattleTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
 modal_body = _label(modal, "", Rect2(515, 380, 570, 129), 24, BattleTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
 modal_primary = _button(modal, "", Rect2(569, 536, 220, 52), _modal_primary)
 modal_secondary = _button(modal, "保留", Rect2(811, 536, 220, 52), func() -> void: battle.choose_counter(false))
 modal.visible = false

func refresh() -> void:
 player_status.text = "生命  %d / 30\n护盾  %d" % [battle.player_hp, battle.player_block]
 enemy_name.text = battle.enemy.data.display_name.split(" / ")[0]
 enemy_art.appearance = battle.enemy.data.appearance
 enemy_hp_bar.max_value = battle.enemy.data.max_hp
 enemy_hp_bar.value = battle.enemy.hp
 enemy_status.text = "生命 %d / %d   ·   护盾 %d   ·   灼烧 %d" % [battle.enemy.hp, battle.enemy.data.max_hp, battle.enemy.block, battle.enemy.burn]
 intent.text = battle.intent_text().replace("ATTACK","攻击").replace("DEFENSE","防御").replace("SPECIAL","蓄力").replace("DANGER","危险攻击")
 intent.add_theme_color_override("font_color",BattleTheme.RED if battle.enemy.current_intent().category==EnemyIntent.Category.DANGER else BattleTheme.GOLD)
 turn_label.text = "回合  %02d" % battle.turn_number
 energy_label.text = "%d / 3" % battle.energy
 pile_labels[0].text = str(battle.deck.draw_pile.size())
 pile_labels[1].text = str(battle.deck.discard_pile.size())
 pile_labels[2].text = str(battle.deck.disabled_pile.size())
 var action := battle.phase == BattleState.Phase.PLAYER_ACTION
 adjust_button.disabled = not action or not battle.adjust_available
 adjust_button.text = "调整 · 免费" if battle.adjust_available else "调整已使用"
 end_button.disabled = not action
 skip_button.visible = battle.phase == BattleState.Phase.RETAIN_SELECTION
 cancel_button.visible = battle.phase in [BattleState.Phase.RETAIN_SELECTION, BattleState.Phase.ADJUST_SELECTION]
 match battle.phase:
  BattleState.Phase.ADJUST_SELECTION:
   prompt_label.text = "调整：点击手牌换牌"
  BattleState.Phase.RETAIN_SELECTION:
   prompt_label.text = "选择一张保留，或跳过"
  BattleState.Phase.ENEMY_TURN:
   prompt_label.text = "敌人行动中……"
  _:
   prompt_label.text = "点击出牌，悬停查看"
 focus_label.text = "专注就绪\n下一张攻击 / 防御 +%d" % battle.focus_bonus if battle.focus_bonus else ""
 _refresh_card_views()
 for slot in 4:
  var requested := battle.deck.slot_type(slot)
  slot_labels[slot].text = ["攻击槽", "防御槽", "技能槽", "自由槽"][slot] if requested >= 0 else "自由槽"
 counter_label.text = "反击\n未埋伏" if battle.counter.card == null else "%s\n%s" % [battle.counter.card.data.display_name.split(" / ")[0], "准备中" if battle.counter.state == BattleState.CounterState.PREPARING else "已就绪"]
 field_label.text = "场地\n未设置" if battle.field.card == null else "%s\n剩余 %d 回合" % [battle.field.card.data.display_name.split(" / ")[0], battle.field.remaining_turns]
 var recent: Array[String] = []
 for index in range(maxi(0, battle.history.size() - 2), battle.history.size()):
  recent.append(battle.history[index])
 log_label.text = "\n".join(recent)
 modal.visible = battle.phase in [BattleState.Phase.COUNTER_WINDOW, BattleState.Phase.VICTORY, BattleState.Phase.DEFEAT]
 if modal.visible:
  var is_counter := battle.phase == BattleState.Phase.COUNTER_WINDOW
  modal_secondary.visible = is_counter
  modal_primary.position.x = 569 if is_counter else 690
  if is_counter:
   modal_title.text = "反击时机"
   var effect := battle.counter.effect_data()
   modal_body.text = "敌人准备发动攻击。\n%s\n总伤害减免 %d · 反击 %d 伤害" % [battle.counter.card.data.display_name, int(effect.get("reduction", 0)), int(effect.get("damage", 0)) + battle.equipment.counter_bonus()]
   modal_primary.text = "发动反击"
  else:
   modal_title.text = "VICTORY" if battle.phase == BattleState.Phase.VICTORY else "DEFEAT"
   modal_body.text = "战斗胜利！" if battle.phase == BattleState.Phase.VICTORY else "勇者倒下了。再试一次。"
   modal_body.text += "\n第 %d 回合 · 剩余生命 %d / 30" % [battle.turn_number, battle.player_hp]
   modal_primary.text = ("领取奖励 →" if battle.phase == BattleState.Phase.VICTORY else "查看结算 →") if campaign_mode else "Restart Battle / 重开"
 if battle.player_block > _last_block:
  _spawn_fx("shield",Vector2(160,114),BattleTheme.BLUE)
  _popup("护盾 +%d"%(battle.player_block-_last_block),Vector2(52,140),BattleTheme.BLUE)
 var attack_count := battle.cards_played[CardData.Type.ATTACK]
 if battle.turn_number==_last_turn and attack_count!=_last_attack_count and battle.equipment.triggered_burn(attack_count)>0:
  _pulse_equipment(0)
 _last_turn=battle.turn_number
 _last_attack_count=attack_count
 _last_block=battle.player_block
 debug_panel.refresh(battle)

func _make_card(card: CardInstance, compact: bool = false) -> CardView:
 var result := CardView.new()
 result.setup(card, compact)
 if battle.phase == BattleState.Phase.PLAYER_ACTION and card.data.energy_cost > battle.energy:
  result.modulate = Color(0.6, 0.6, 0.6, 1)
 result.modulate.a = 0.25
 create_tween().tween_property(result, "modulate:a", 1.0, 0.2)
 result.selected.connect(battle.click_card)
 result.mouse_filter = Control.MOUSE_FILTER_STOP if battle.phase in [BattleState.Phase.PLAYER_ACTION, BattleState.Phase.ADJUST_SELECTION, BattleState.Phase.RETAIN_SELECTION] else Control.MOUSE_FILTER_IGNORE
 return result

func _slot_position(slot: int) -> Vector2:
 return Vector2(336 + slot * 240, 548)

func _show_feedback(message: String) -> void:
 toast.text = message
 toast_timer.start()

func _modal_primary() -> void:
 if battle.phase == BattleState.Phase.COUNTER_WINDOW:
  battle.choose_counter(true)
 elif campaign_mode:
  completed.emit(battle.phase == BattleState.Phase.VICTORY)
 else:
  toast.text = ""
  battle.start_battle()

func _toggle_debug() -> void:
 debug_panel.visible = not debug_panel.visible
 if debug_panel.visible:
  debug_panel.refresh(battle)

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_SLASH:
   _toggle_help()
  elif event.keycode == KEY_F3:
   _toggle_debug()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_ESCAPE:
   if help_overlay.visible:
    help_overlay.hide()
   elif debug_panel.visible:
    debug_panel.hide()
   else:
    battle.cancel_selection()

func _panel(parent: Node, bounds: Rect2, color: Color = BattleTheme.PANEL,
  border: Color = Color("344355")) -> Panel:
 var result := Panel.new()
 result.position = bounds.position
 result.size = bounds.size
 result.add_theme_stylebox_override("panel", BattleTheme.box(color, border))
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(result)
 return result

func _label(parent: Node, value: String, bounds: Rect2, font_size: int = 18,
  color: Color = BattleTheme.TEXT, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 var result := Label.new()
 result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 result.text = value
 result.position = bounds.position
 result.size = bounds.size
 result.add_theme_font_size_override("font_size", font_size)
 result.add_theme_color_override("font_color", color)
 result.horizontal_alignment = alignment
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(result)
 return result

func _button(parent: Node, value: String, bounds: Rect2, callback: Callable) -> Button:
 var result := Button.new()
 result.text = value
 result.position = bounds.position
 result.size = bounds.size
 result.add_theme_font_size_override("font_size", 24)
 result.pressed.connect(func():
  _ui_click()
  callback.call())
 result.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 parent.add_child(result)
 return result


func _visual_feedback(kind: String, amount: int) -> void:
 if not is_instance_valid(sound): return
 sound.stream=load("res://assets/audio/%s.wav"%("card" if kind=="card" else ("burn" if kind=="burn" else ("block" if kind=="block" else "hit"))))
 sound.play()
 if kind=="card":
  _animate_played_card()
  return
 var text:=str(amount)
 var tint:=BattleTheme.RED
 var point:=Vector2(705,365)
 var fx_kind:="hit"
 if kind=="block":
  text="格挡 %d"%amount
  tint=BattleTheme.BLUE
  point=Vector2(38,145)
  fx_kind="shield"
 elif kind=="player_damage":
  text="-%d"%amount
  point=Vector2(48,142)
 elif kind=="burn":
  text="灼烧 %d"%amount
  tint=Color("e8aa65")
  point=Vector2(815,431)
  fx_kind="burn"
 elif kind=="counter":
  text="反击 %d"%amount
  tint=BattleTheme.GOLD
  point=Vector2(640,435)
  fx_kind="counter"
  if battle.equipment.counter_bonus()>0:_pulse_equipment(2)
 if kind=="enemy_damage":
  if _popup_elapsed>0.2:_popup_sequence=0
  point+=Vector2((_popup_sequence%3)*60,(_popup_sequence/3)*30)
  _popup_sequence+=1
  _popup_time=Time.get_ticks_msec()
  _popup_elapsed=0.0
 _popup(text,point,tint)
 _spawn_fx(fx_kind,Vector2(800,393) if kind not in ["block","player_damage"] else Vector2(160,110),tint)
 if kind in ["enemy_damage","counter"]:
  enemy_art.hit_flash=0.18
  enemy_art.recoil=8
func _popup(value: String, point: Vector2, color: Color) -> void:
 var popup:=_label(self,value,Rect2(point,Vector2(210,48)),34,color,HORIZONTAL_ALIGNMENT_CENTER)
 popup.z_index=45
 popup.add_theme_color_override("font_shadow_color",Color("0b1420"))
 popup.add_theme_constant_override("shadow_offset_x",2)
 popup.add_theme_constant_override("shadow_offset_y",2)
 var tween:=create_tween().set_parallel()
 tween.tween_property(popup,"position:y",point.y-54,0.65)
 tween.tween_property(popup,"modulate:a",0.0,0.65).set_delay(0.1)
 tween.chain().tween_callback(popup.queue_free)
func _spawn_fx(kind: String, point: Vector2, tint: Color) -> void:
 var fx:=BattleVisualFX.new()
 fx.kind=kind
 fx.tint=tint
 fx.position=point
 add_child(fx)
func _pulse_equipment(slot: int) -> void:
 if slot>=equipment_tiles.size():return
 equipment_tiles[slot].modulate=Color("ffe6a2")
 create_tween().tween_property(equipment_tiles[slot],"modulate",Color.WHITE,0.4)
 _spawn_fx("equipment",equipment_tiles[slot].position+Vector2(22,28),BattleTheme.GOLD)
func _ui_click() -> void:
 if sound:
  sound.stream=load("res://assets/audio/ui_click.wav")
  sound.play()
func _build_help() -> void:
 help_overlay=Control.new()
 help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 help_overlay.z_index=90
 var shade:=ColorRect.new()
 shade.color=Color(0.03,0.05,0.08,0.88)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 help_overlay.add_child(shade)
 add_child(help_overlay)
 _panel(help_overlay,Rect2(310,185,980,515),BattleTheme.PANEL,BattleTheme.GOLD)
 _label(help_overlay,"战术手册",Rect2(350,215,860,50),36,BattleTheme.GOLD)
 _label(help_overlay,"每回合 3 能量。攻击、防御、技能和自由槽依次补牌。\n调整：每回合一次免费换牌，类型不限。\n结束回合：保留一张基础手牌，额外牌不能保留。\n反击：埋伏一轮后就绪，敌人攻击时主动选择发动。\n装备、卡牌悬停可看完整效果。F3 查看详细战术记录。\n敌人只公开意图类别；洞察能揭示当前完整效果。",Rect2(350,290,885,285),26)
 _button(help_overlay,"继续战斗",Rect2(575,605,450,55),_toggle_help)
 help_overlay.hide()
func _toggle_help() -> void:
 help_overlay.visible=not help_overlay.visible
func _refresh_card_views() -> void:
 var wanted: Array[CardInstance]=[]
 for card in battle.hand+battle.extra_cards:
  if card:wanted.append(card)
 for card in _views.keys():
  if not wanted.has(card):
   var old:CardView=_views[card]
   old.get_parent().remove_child(old)
   old.queue_free()
   _views.erase(card)
 for slot in 4:
  var card:=battle.hand[slot]
  if card:
   var view:CardView=_views.get(card)
   if view==null:
    view=_make_card(card)
    card_layer.add_child(view)
    _views[card]=view
   view.position=_slot_position(slot)
   _card_state(view)
 for card in battle.extra_cards:
  var view:CardView=_views.get(card)
  if view==null:
   view=_make_card(card,true)
   extra_row.add_child(view)
   _views[card]=view
  _card_state(view)
func _card_state(view: CardView) -> void:
 var available:=battle.phase==BattleState.Phase.PLAYER_ACTION and view.card.data.energy_cost>battle.energy
 var alpha:=view.modulate.a
 view.modulate=Color(0.65,0.65,0.65,alpha) if available else Color(1,1,1,alpha)
 view.mouse_filter=Control.MOUSE_FILTER_STOP if battle.phase in [BattleState.Phase.PLAYER_ACTION,BattleState.Phase.ADJUST_SELECTION,BattleState.Phase.RETAIN_SELECTION] else Control.MOUSE_FILTER_IGNORE
func _animate_played_card() -> void:
 for card in _views:
  if not battle.hand.has(card) and not battle.extra_cards.has(card):
   var old:CardView=_views[card]
   var ghost:=CardView.new()
   ghost.setup(card,old.compact)
   ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
   ghost.focus_mode=Control.FOCUS_NONE
   ghost.pivot_offset=Vector2.ZERO
   ghost.position=old.global_position-global_position
   ghost.scale=Vector2.ONE
   ghost.z_index=40
   add_child(ghost)
   card_transition_count+=1
   var tween:=create_tween().set_parallel()
   tween.tween_property(ghost,"position",Vector2(685,340),0.22)
   tween.tween_property(ghost,"scale",Vector2(0.6,0.6),0.22)
   tween.tween_property(ghost,"modulate:a",0.0,0.22)
   tween.chain().tween_callback(ghost.queue_free)
   break



func _equipment_brief(item: EquipmentData) -> String:
 var brief: Array[String]=[]
 if item.attack_hit_bonus>0:brief.append("命中 +%d"%item.attack_hit_bonus)
 if item.hp_damage_reduction>0:brief.append("减伤 %d"%item.hp_damage_reduction)
 if item.counter_damage_bonus>0:brief.append("反击 +%d"%item.counter_damage_bonus)
 if item.applied_burn_bonus>0:brief.append("灼烧 +%d"%item.applied_burn_bonus)
 if item.preserve_player_block:brief.append("保留护盾")
 return " · ".join(brief) if not brief.is_empty() else item.description


func _process(delta: float) -> void:
 _popup_elapsed+=delta

