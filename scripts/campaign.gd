class_name CampaignUI
extends Control
const BATTLE := preload("res://scenes/battle.tscn")
var page: Control
var battle_ui: BattleUI
var screen := "menu"
var route := "guard"
var encounter := 0
var run_seed := 20261010
var cards: Array[CardData] = []
var items: Array[EquipmentData] = []
var hp := 30
var total_turns := 0
var battles_won := 0
var choices: Array[String] = []
var card_choice: CardData
var item_choice: EquipmentData
var next_button: Button
var selection_label: Label
var error_label: Label
var sound: AudioStreamPlayer
var reward_cards: Array[CardData] = []
var reward_items: Array[EquipmentData] = []
const ENEMIES := ["moss_guard", "ash_raider", "furnace_king"]
func _ready() -> void:
 theme = BattleTheme.make_theme()
 sound = AudioStreamPlayer.new()
 sound.volume_db = -12
 add_child(sound)
 show_menu()
func _reset_page(next: String) -> void:
 screen = next
 if is_instance_valid(page):
  remove_child(page)
  page.queue_free()
 battle_ui = null
 page = Control.new()
 page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(page)
 var bg := BattleBackdrop.new()
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 page.add_child(bg)
 page.modulate.a=0.3
 create_tween().tween_property(page,"modulate:a",1.0,0.22)
func label_at(value: String, rect: Rect2, font_size := 24, color := BattleTheme.TEXT) -> Label:
 var label := Label.new()
 label.text = value
 label.position = rect.position
 label.size = rect.size
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 page.add_child(label)
 return label
func button_at(value: String, rect: Rect2, callback: Callable) -> Button:
 var button := Button.new()
 button.text = value
 button.position = rect.position
 button.size = rect.size
 button.add_theme_font_size_override("font_size", 24)
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 button.pressed.connect(func():
  sound.stream=load("res://assets/audio/ui_click.wav")
  sound.play()
  callback.call())
 page.add_child(button)
 return button
func panel(rect: Rect2) -> void:
 var panel_node := Panel.new()
 panel_node.position = rect.position
 panel_node.size = rect.size
 panel_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel_node.add_theme_stylebox_override("panel", BattleTheme.box())
 page.add_child(panel_node)
func show_menu() -> void:
 _reset_page("menu")
 panel(Rect2(130, 130, 1340, 640))
 label_at("EMBER / 余烬试炼", Rect2(200, 160, 1100, 90), 64, BattleTheme.GOLD)
 label_at("三场战斗，一套属于你的构筑。", Rect2(205, 275, 1050, 60), 30)
 label_at("分类抽牌 · 每回合 3 能量 · 保留与调整 · 主动反击\n击败守卫、游侠与熔炉之王。每次胜利选择卡牌和装备，恢复 8 生命。", Rect2(205, 355, 1120, 110), 25, BattleTheme.MUTED)
 button_at("守望者  /  防守反击", Rect2(205, 510, 555, 85), func(): begin_run("guard"))
 button_at("余烬行者  /  多段灼烧", Rect2(825, 510, 555, 85), func(): begin_run("burn"))
 label_at("守望者：盾击 + 守势反击 + 守望指环\n余烬行者：火花双斩 + 引燃 + 炭火指环", Rect2(205, 630, 1110, 95), 24, BattleTheme.MUTED)
 error_label = label_at("鼠标操作 · 悬停查看完整卡牌 · F3 战术日志 · Esc 取消选择", Rect2(150, 810, 1300, 50), 21, BattleTheme.MUTED)
func begin_run(selected_route: String) -> void:
 var errors := ResourceValidator.validate_cards(ResourceValidator.catalog())
 if not errors.is_empty():
  error_label.text = "资源校验失败：" + "; ".join(errors)
  return
 route = selected_route
 cards.assign(load("res://resources/decks/starter.tres").cards)
 for id in (["shield_strike", "riposte"] if route == "guard" else ["cinder", "kindle"]): cards.append(load("res://resources/cards/%s.tres" % id))
 items.assign([load("res://resources/equipment/ember_sword.tres"), load("res://resources/equipment/leather_armor.tres"), load("res://resources/equipment/%s.tres" % ("watch_ring" if route == "guard" else "coal_ring"))])
 hp = 30
 encounter = 0
 total_turns = 0
 battles_won = 0
 choices.clear()
 start_encounter()
func start_encounter() -> void:
 _reset_page("battle")
 var definition := DeckDefinition.new()
 definition.cards.assign(cards)
 battle_ui = BATTLE.instantiate()
 battle_ui.auto_start = false
 battle_ui.campaign_mode = true
 battle_ui.battle = battle_ui.get_node("BattleManager")
 battle_ui.battle.configure(definition, load("res://resources/enemies/%s.tres" % ENEMIES[encounter]), items, hp)
 battle_ui.battle.start_battle(run_seed + encounter)
 page.add_child(battle_ui)
 battle_ui.completed.connect(finish_encounter)
 battle_ui.modal_primary.text = "领取奖励 →"
 label_at("试炼 %d / 3  ·  %s" % [encounter + 1, "守望者" if route == "guard" else "余烬行者"], Rect2(550, 16, 620, 35), 20, BattleTheme.GOLD)
 button_at("返回主菜单", Rect2(24, 610, 276, 24), show_menu).add_theme_font_size_override("font_size", 15)
func finish_encounter(won: bool) -> void:
 if screen != "battle": return
 hp = battle_ui.battle.player_hp
 total_turns += battle_ui.battle.turn_number
 if not won:
  show_results(false)
  return
 battles_won += 1
 if encounter == 2:
  show_results(true)
 else:
  show_rewards()
func show_rewards() -> void:
 _reset_page("reward")
 card_choice = null
 item_choice = null
 hp = mini(30, hp + 8)
 panel(Rect2(100, 85, 1400, 750))
 label_at("战斗胜利 / 构筑你的下一步", Rect2(150, 110, 1280, 60), 42, BattleTheme.GOLD)
 label_at("生命恢复至 %d / 30。选择 1 张卡牌 + 1 件装备。装备替换同槽，卡牌加入构筑。" % hp, Rect2(150, 180, 1300, 65), 23)
 reward_cards.clear()
 var ids := ["shield_strike", "bastion", "cinder"] if encounter == 0 else ["riposte", "bulwark", "flurry"]
 for index in ids.size():
  var card: CardData = load("res://resources/cards/%s.tres" % ids[index])
  reward_cards.append(card)
  var view := CardView.new()
  view.setup(CardInstance.new(card, 100 + index))
  view.position = Vector2(310 + index * 380, 270)
  view.hover_scale = 1.08
  view.selected.connect(func(instance: CardInstance): choose_card(instance.data))
  page.add_child(view)
 reward_items.clear()
 for index in 2:
  var id: String = ["tower_armor", "duelist_blade"][index] if encounter == 0 else ["watch_ring", "coal_ring"][index]
  var item: EquipmentData = load("res://resources/equipment/%s.tres" % id)
  reward_items.append(item)
  button_at(item.display_name + "\n" + item.description, Rect2(155 + index * 660, 626, 620, 84), func(): choose_item(item)).add_theme_font_size_override("font_size", 21)
 selection_label = label_at("请选择卡牌与装备", Rect2(155, 740, 840, 65), 24, BattleTheme.BLUE)
 next_button = button_at("进入下一战 →", Rect2(1100, 750, 335, 58), accept_rewards)
 next_button.disabled = true
func choose_card(card: CardData) -> void:
 if screen != "reward" or not reward_cards.has(card): return
 card_choice = card
 update_selection()
func choose_item(item: EquipmentData) -> void:
 if screen != "reward" or not reward_items.has(item): return
 item_choice = item
 update_selection()
func update_selection() -> void:
 selection_label.text = "卡牌：%s\n装备：%s" % [card_choice.display_name if card_choice else "未选择", item_choice.display_name if item_choice else "未选择"]
 next_button.disabled = card_choice == null or item_choice == null
func accept_rewards() -> void:
 if screen != "reward" or card_choice == null or item_choice == null: return
 cards.append(card_choice)
 for index in items.size():
  if items[index].slot == item_choice.slot:
   items[index] = item_choice
   break
 choices.append(card_choice.display_name + " / " + item_choice.display_name)
 encounter += 1
 start_encounter()
func show_results(won: bool) -> void:
 _reset_page("result")
 panel(Rect2(180, 150, 1240, 600))
 label_at("试炼完成" if won else "试炼中止", Rect2(250, 190, 1100, 95), 60, BattleTheme.GOLD)
 label_at("%s · 胜利 %d / 3 · 总计 %d 回合 · 剩余生命 %d / 30" % ["守望者" if route == "guard" else "余烬行者", battles_won, total_turns, hp], Rect2(250, 320, 1100, 70), 27)
 label_at("你的选择\n" + "\n".join(choices), Rect2(250, 405, 1080, 135), 23, BattleTheme.MUTED)
 button_at("再次挑战", Rect2(250, 620, 480, 65), func(): begin_run(route))
 button_at("返回主菜单", Rect2(870, 620, 480, 65), show_menu)
 sound.stream = load("res://assets/audio/win.wav")
 sound.play()
