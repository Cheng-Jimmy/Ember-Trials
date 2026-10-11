class_name BattleManager
extends Node

signal visual_event(kind: String, amount: int)
signal changed
signal feedback(message: String)
signal phase_changed(phase: BattleState.Phase)

const MAX_HP := 30
const MAX_ENERGY := 3
const STARTER: DeckDefinition = preload("res://resources/decks/starter.tres")
const SLIME: EnemyData = preload("res://resources/enemies/green_slime.tres")

var phase: BattleState.Phase = BattleState.Phase.PLAYER_TURN_START
var turn_number: int = 0
var player_hp: int = MAX_HP
var player_block: int = 0
var energy: int = 0
var deck := DeckManager.new()
var enemy: BattleEnemy
var equipment := BattleEquipment.new()
var counter := CounterSlot.new()
var field := FieldSlot.new()
var hand: Array[CardInstance] = [null, null, null, null]
var extra_cards: Array[CardInstance] = []
var retained_card: CardInstance
var adjust_available: bool = true
var focus_bonus: int = 0
var cards_played: Array[int] = [0, 0, 0]
var history: Array[String] = []
var enemy_delay: float = 0.65
var _battle_generation: int = 0
var configured_deck: DeckDefinition = STARTER
var configured_enemy: EnemyData = SLIME
var configured_equipment: Array[EquipmentData] = []
var starting_hp := MAX_HP
var use_custom_equipment := false
var usage: Dictionary = {}
func configure(definition: DeckDefinition, opponent: EnemyData, items: Array[EquipmentData], hp: int = MAX_HP) -> void:
 configured_deck = definition
 configured_enemy = opponent
 configured_equipment.assign(items)
 starting_hp = clampi(hp, 1, MAX_HP)
 use_custom_equipment = true


func start_battle(random_seed: int = -1) -> void:
 _battle_generation += 1
 deck.setup(configured_deck, random_seed)
 enemy = BattleEnemy.new(configured_enemy)
 equipment.slots.assign([
  preload("res://resources/equipment/ember_sword.tres"),
  preload("res://resources/equipment/leather_armor.tres"),
  preload("res://resources/equipment/ruby_ring.tres")])
 if use_custom_equipment:
  equipment.slots.assign(configured_equipment)
 player_hp = starting_hp
 usage.clear()
 player_block = 0
 energy = 0
 turn_number = 0
 hand.assign([null, null, null, null])
 extra_cards.clear()
 retained_card = null
 counter = CounterSlot.new()
 field = FieldSlot.new()
 history.clear()
 record("战斗开始。")
 _start_player_turn()

func _set_phase(next: BattleState.Phase) -> void:
 phase = next
 phase_changed.emit(phase)

func _start_player_turn() -> void:
 _set_phase(BattleState.Phase.PLAYER_TURN_START)
 # Block protects through the whole enemy turn, including a counter window.
 # Expire leftovers here, before energy restoration and drawing the new hand.
 if equipment.clears_block():
  if player_block > 0:
   record("玩家回合开始：清除剩余 %d 护盾。" % player_block)
  player_block = 0
 if field.card:
  for effect in field.card.data.effect_data:
   if effect.get("op") == "field":
    player_block += int(effect.get("block_each_turn", 0))
 turn_number += 1
 counter.on_player_turn_start(turn_number)
 set_energy(MAX_ENERGY)
 adjust_available = true
 focus_bonus = 0
 cards_played.assign([0, 0, 0])
 for slot in 4:
  if hand[slot] == null:
   hand[slot] = deck.draw_for_slot(slot)
 _set_phase(BattleState.Phase.PLAYER_ACTION)
 record("第 %d 回合 · 能量恢复至 3。" % turn_number)
 changed.emit()

func set_energy(value: int) -> void:
 energy = clampi(value, 0, MAX_ENERGY)

func click_card(card: CardInstance) -> void:
 match phase:
  BattleState.Phase.PLAYER_ACTION:
   play_card(card)
  BattleState.Phase.ADJUST_SELECTION:
   adjust_card(card)
  BattleState.Phase.RETAIN_SELECTION:
   choose_retain(card)

func begin_adjust() -> void:
 if phase != BattleState.Phase.PLAYER_ACTION or not adjust_available:
  return
 if not _has_cards():
  feedback.emit("没有可调整的手牌。")
  return
 _set_phase(BattleState.Phase.ADJUST_SELECTION)
 changed.emit()

func cancel_selection() -> void:
 if phase == BattleState.Phase.ADJUST_SELECTION or phase == BattleState.Phase.RETAIN_SELECTION:
  _set_phase(BattleState.Phase.PLAYER_ACTION)
  changed.emit()

func adjust_card(card: CardInstance) -> void:
 if phase != BattleState.Phase.ADJUST_SELECTION or not _in_hand(card):
  return
 var slot := hand.find(card)
 var extra_index := extra_cards.find(card)
 # Hold the selected card aside while drawing: never redraw this same card.
 # If draw is empty, only the previous discard pile may be recycled.
 var replacement := deck.draw_random()
 if replacement == null:
  feedback.emit("没有其他可抽取的牌，调整未消耗。")
  return
 _remove_from_hand(card)
 deck.discard(card)
 if slot >= 0:
  hand[slot] = replacement
 else:
  extra_cards.insert(extra_index, replacement)
 adjust_available = false
 _set_phase(BattleState.Phase.PLAYER_ACTION)
 record("调整：%s → %s（不限制类型）。" % [card.data.display_name, replacement.data.display_name])
 changed.emit()

func play_card(card: CardInstance) -> bool:
 if phase != BattleState.Phase.PLAYER_ACTION or not _in_hand(card):
  return false
 if energy < card.data.energy_cost:
  feedback.emit("能量不足 · 需要 %d 点能量" % card.data.energy_cost)
  return false
 set_energy(energy - card.data.energy_cost)
 _remove_from_hand(card)
 var temporary_bonus := 0
 if card.data.card_type != CardData.Type.SKILL:
  temporary_bonus = focus_bonus
  focus_bonus = 0
 cards_played[card.data.card_type] += 1
 usage[card.data.id] = int(usage.get(card.data.id, 0)) + 1
 visual_event.emit("card", card.data.card_type)
 record("使用 %s。" % card.data.display_name)
 EffectResolver.apply(self, card, temporary_bonus)
 if card.data.card_type == CardData.Type.ATTACK and enemy.hp > 0:
  var burn := equipment.triggered_burn(cards_played[CardData.Type.ATTACK])
  enemy.burn += burn
  if burn > 0:
   record("余烬剑：第 2 张攻击牌，施加 %d 层灼烧。" % burn)
 if not card.data.tags.has("COUNTER") and not card.data.tags.has("FIELD"):
  deck.discard(card)
 _check_outcome()
 changed.emit()
 return true

func _in_hand(card: CardInstance) -> bool:
 return card != null and (hand.has(card) or extra_cards.has(card))

func _remove_from_hand(card: CardInstance) -> void:
 var slot := hand.find(card)
 if slot >= 0:
  hand[slot] = null
 else:
  extra_cards.erase(card)
 if retained_card == card:
  retained_card = null

func damage_enemy(base: int, card_modifier: int = 0, temporary_modifier: int = 0,
  equipment_modifier: int = 0) -> void:
 var result := DamageResolver.resolve(base, enemy.block, card_modifier,
  temporary_modifier, equipment_modifier)
 enemy.block = result.block
 enemy.hp = maxi(0, enemy.hp - int(result.hp_damage))
 visual_event.emit("enemy_damage", int(result.hp_damage))
 record("敌人受到 %d 伤害（护盾吸收 %d）。" % [result.hp_damage, result.absorbed])

func damage_player(base: int, reduction: int = 0) -> void:
 var result := DamageResolver.resolve(base, player_block, 0, 0, 0,
  -reduction, equipment.hp_reduction())
 player_block = result.block
 player_hp = maxi(0, player_hp - int(result.hp_damage))
 visual_event.emit("player_damage" if result.hp_damage > 0 else "block", int(result.hp_damage) if result.hp_damage > 0 else int(result.absorbed))
 record("你受到 %d 伤害（护盾吸收 %d，皮甲减伤最多 %d）。" % [
  result.hp_damage, result.absorbed, equipment.hp_reduction()])

func reveal_current_intent() -> void:
 enemy.intent_revealed = true
 record("已揭示：%s" % enemy.current_intent().describe(enemy.attack_bonus).replace("\n", " · "))
 changed.emit()

func intent_text() -> String:
 if enemy.intent_revealed:
  return enemy.current_intent().describe(enemy.attack_bonus)
 return "%s\n?  具体效果隐藏" % EnemyIntent.Category.keys()[enemy.current_intent().category]

func end_turn() -> void:
 if phase != BattleState.Phase.PLAYER_ACTION:
  return
 retained_card = null
 if _has_cards():
  _set_phase(BattleState.Phase.RETAIN_SELECTION)
  changed.emit()
  return
 _finish_player_turn()

func _has_cards() -> bool:
 for card in hand:
  if card:
   return true
 return not extra_cards.is_empty()

func choose_retain(card: CardInstance) -> void:
 if phase != BattleState.Phase.RETAIN_SELECTION:
  return
 if card != null and not hand.has(card):
  feedback.emit("只能保留四个基础槽中的一张牌；额外手牌不能保留。")
  return
 retained_card = card
 if card:
  record("保留 %s，下一回合保持原槽位。" % card.data.display_name)
 _finish_player_turn()

func _finish_player_turn() -> void:
 _set_phase(BattleState.Phase.PLAYER_END)
 for slot in 4:
  if hand[slot] != retained_card:
   deck.discard(hand[slot])
   hand[slot] = null
 for card in extra_cards:
  deck.discard(card)
 extra_cards.clear()
 set_energy(0)
 focus_bonus = 0
 _set_phase(BattleState.Phase.ENEMY_TURN)
 changed.emit()
 if enemy_delay > 0.0 and is_inside_tree():
  get_tree().create_timer(enemy_delay).timeout.connect(_execute_enemy_turn.bind(_battle_generation))
 else:
  _execute_enemy_turn(_battle_generation)

func _execute_enemy_turn(generation: int) -> void:
 if generation != _battle_generation or phase != BattleState.Phase.ENEMY_TURN:
  return
 enemy.block = 0
 if enemy.current_intent().category in [EnemyIntent.Category.ATTACK, EnemyIntent.Category.DANGER] and counter.state == BattleState.CounterState.READY:
  _set_phase(BattleState.Phase.COUNTER_WINDOW)
  changed.emit()
  return
 _resolve_enemy_action()

func choose_counter(activate: bool) -> void:
 if phase != BattleState.Phase.COUNTER_WINDOW:
  return
 _set_phase(BattleState.Phase.ENEMY_TURN)
 var reduction := 0
 if activate:
  var effect := counter.effect_data()
  reduction = int(effect.get("reduction", 0))
  damage_enemy(int(effect.get("damage", 0)) + equipment.counter_bonus())
  visual_event.emit("counter", int(effect.get("damage", 0)) + equipment.counter_bonus())
  deck.discard(counter.consume())
  record("反击发动：此次攻击伤害减少 %d。" % reduction)
  if _check_outcome():
   changed.emit()
   return
 else:
  record("保留反击，敌人继续行动。")
 _resolve_enemy_action(reduction)

func _resolve_enemy_action(reduction: int = 0) -> void:
 var intent := enemy.current_intent()
 record("敌人行动：%s。" % intent.display_name)
 match intent.category:
  EnemyIntent.Category.ATTACK, EnemyIntent.Category.DANGER:
   var remaining_reduction := reduction
   for hit in intent.hits:
    var damage := intent.damage + enemy.attack_bonus
    var hit_reduction := mini(damage, remaining_reduction)
    remaining_reduction -= hit_reduction
    damage_player(damage, hit_reduction)
    if _check_outcome():
     changed.emit()
     return
   enemy.attack_bonus = 0
  EnemyIntent.Category.DEFENSE:
   enemy.block += intent.block
   enemy.burn = maxi(0, enemy.burn - intent.cleanse)
  EnemyIntent.Category.SPECIAL:
   enemy.attack_bonus += intent.next_attack_bonus
 if enemy.burn > 0:
  record("灼烧结算：%d 层。" % enemy.burn)
  visual_event.emit("burn", enemy.burn)
  damage_enemy(enemy.burn)
  enemy.burn = maxi(0, enemy.burn - 1)
 deck.discard(field.on_round_end())
 if _check_outcome():
  changed.emit()
  return
 enemy.advance_intent()
 _start_player_turn()

func arm_counter(card: CardInstance) -> void:
 deck.discard(counter.replace(card, turn_number))
 record("反击已埋伏：准备中，下个玩家回合开始就绪。")

func replace_field(card: CardInstance) -> void:
 deck.discard(field.replace(card))

func _check_outcome() -> bool:
 if player_hp <= 0:
  _set_phase(BattleState.Phase.DEFEAT)
  return true
 if enemy.hp <= 0:
  _set_phase(BattleState.Phase.VICTORY)
  return true
 return false

func record(message: String) -> void:
 history.append(message)
 if history.size() > 80:
  history.pop_front()
