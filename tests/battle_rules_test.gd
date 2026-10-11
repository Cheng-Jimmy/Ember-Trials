extends SceneTree

var checks: int = 0
var battle: BattleManager

func _initialize() -> void:
 call_deferred("_run")

func verify(condition: bool, label: String) -> void:
 checks += 1
 if not condition:
  push_error("FAILED: " + label)
  quit(1)
  assert(condition, label)

func fresh(seed_value: int = 8) -> BattleManager:
 if is_instance_valid(battle):
  battle.free()
 battle = BattleManager.new()
 battle.enemy_delay = 0.0
 root.add_child(battle)
 battle.start_battle(seed_value)
 return battle

func card_from_deck(id: String) -> CardInstance:
 for pile in [battle.deck.draw_pile, battle.deck.discard_pile, battle.hand, battle.extra_cards]:
  for index in pile.size():
   var card: CardInstance = pile[index]
   if card != null and card.data.id == id:
    if pile == battle.hand:
     pile[index] = null
    else:
     pile.remove_at(index)
    return card
 return null

func give(id: String, slot: int = -1) -> CardInstance:
 var card := card_from_deck(id)
 verify(card != null, "Test setup card exists: " + id)
 if slot < 0:
  battle.extra_cards.append(card)
 else:
  battle.deck.discard(battle.hand[slot])
  battle.hand[slot] = card
 return card

func pass_turn() -> void:
 battle.end_turn()
 if battle.phase == BattleState.Phase.RETAIN_SELECTION:
  battle.choose_retain(null)

func _run() -> void:
 fresh()
 verify(battle.player_hp == 30 and battle.energy == 3, "Initial HP and energy")
 for slot in 3:
  verify(battle.hand[slot].data.card_type == slot, "Fixed slot %d" % slot)
 battle.set_energy(99)
 verify(battle.energy == 3, "Energy cap")
 battle.set_energy(-5)
 verify(battle.energy == 0, "Energy floor")
 var hp := battle.enemy.hp
 verify(not battle.play_card(battle.hand[0]), "Cannot overspend")
 verify(battle.enemy.hp == hp, "Failed play is non-mutating")
 fresh()
 var multi := give("multi_slash")
 battle.play_card(multi)
 verify(battle.enemy.hp == 27, "Multi Slash = 4 + 4")
 verify(battle.cards_played[0] == 1, "Two hits count as one attack card")
 verify(battle.deck.discard_pile.has(multi), "Played card goes to discard")
 fresh()
 battle.play_card(give("focus"))
 battle.play_card(give("multi_slash"))
 verify(battle.enemy.hp == 23 and battle.focus_bonus == 0, "Focus buffs entire next attack card")
 fresh()
 battle.play_card(give("focus"))
 battle.play_card(give("block"))
 verify(battle.player_block == 8, "Focus on defense")
 battle.play_card(give("slash"))
 verify(battle.enemy.hp == 28, "Focus consumed once")
 fresh()
 battle.play_card(give("slash"))
 battle.play_card(give("parry"))
 verify(battle.player_block == 7, "Parry after attack")
 fresh()
 battle.play_card(give("parry"))
 verify(battle.player_block == 4, "Parry before attack")
 fresh()
 var insight := give("insight", 2)
 var original_slots := battle.hand.duplicate()
 battle.play_card(insight)
 verify(battle.enemy.intent_revealed, "Insight reveals")
 verify(battle.extra_cards.size() == 1, "Insight extra card region")
 verify(battle.hand[0] == original_slots[0] and battle.hand[1] == original_slots[1], "Extra draw preserves base slots")
 verify(battle.intent_text().contains("6"), "Revealed full attack")
 fresh()
 verify(not battle.intent_text().contains("6"), "Intent initially hidden")
 for expected in [1, 2, 3, 0]:
  pass_turn()
  verify(battle.enemy.intent_index == expected, "Intent cycle")
  verify(not battle.enemy.intent_revealed, "Reveal resets next intent")
 verify(battle.enemy.attack_bonus == 3, "Charge sets next attack bonus")
 var hp_before_charge := battle.player_hp
 pass_turn()
 verify(battle.player_hp == hp_before_charge - 8, "Charged strike is 6 + 3 minus armor")
 verify(battle.enemy.attack_bonus == 0, "Charge consumed by next attack")
 fresh()
 var old := battle.hand[1]
 battle.begin_adjust()
 verify(battle.phase == BattleState.Phase.ADJUST_SELECTION, "Adjust selection phase")
 battle.adjust_card(old)
 verify(battle.hand[1] != old and battle.deck.discard_pile.has(old), "Adjust replaces same slot")
 verify(battle.energy == 3 and not battle.adjust_available, "Adjust free, once per turn")
 battle.begin_adjust()
 verify(battle.phase == BattleState.Phase.PLAYER_ACTION, "Adjust cannot repeat")
 var retained := battle.hand[2]
 battle.end_turn()
 verify(battle.phase == BattleState.Phase.RETAIN_SELECTION, "Retain selection phase")
 battle.choose_retain(retained)
 verify(battle.hand[2] == retained and battle.retained_card == retained, "Retain same instance and slot")
 verify(battle.adjust_available and battle.energy == 3, "New turn resets actions")
 _test_deck_edges()
 _test_counter()
 _test_equipment_and_field()
 await _test_block_lifecycle()
 _test_outcomes()
 _test_random_battles()
 print("BATTLE RULE CHECKS PASSED: %d" % checks)
 battle.free()
 quit()

func _test_deck_edges() -> void:
 var definition := DeckDefinition.new()
 definition.cards.assign([load("res://resources/cards/slash.tres"), load("res://resources/cards/focus.tres")])
 var deck := DeckManager.new()
 deck.setup(definition, 2)
 verify(deck.slot_type(1) == -1, "Absent defense type becomes FREE")
 var attack := deck.draw_for_slot(0)
 deck.disable(attack)
 verify(deck.slot_type(0) == 0, "Disabled card still belongs to construction")
 verify(deck.draw_for_slot(0) == null, "Unavailable type does not fall back to FREE")
 var skill := deck.draw_random()
 deck.discard(skill)
 verify(deck.draw_random() == skill, "Discard recycles when draw empty")
 verify(deck.draw_random() == null and deck.disabled_pile.has(attack), "Disabled never recycles")
 deck = DeckManager.new()
 deck.setup(BattleManager.STARTER, 11)
 var attacks: Array[CardInstance] = []
 for card in deck.draw_pile.duplicate():
  if card.data.card_type == CardData.Type.ATTACK:
   deck.draw_pile.erase(card)
   attacks.append(card)
 deck.discard(attacks[0])
 verify(deck.draw_for_slot(0) == attacks[0], "Typed slot recycles discard despite other draw types")
 fresh()
 var selected := give("block", 1)
 var replacement := card_from_deck("slash")
 for card in battle.deck.draw_pile:
  battle.deck.discard(card)
 battle.deck.draw_pile.assign([replacement])
 battle.begin_adjust()
 battle.adjust_card(selected)
 verify(battle.hand[1].data.card_type == CardData.Type.ATTACK, "Adjust may change DEFENSE slot to attack")
 verify(battle.deck.discard_pile.has(selected), "Adjusted card remains discarded")
 battle.end_turn()
 battle.choose_retain(replacement)
 verify(battle.hand[1] == replacement, "Off-type retained card stays in original slot")
 verify_conservation()
 fresh()
 selected = battle.hand[0]
 for card in battle.deck.draw_pile:
  battle.deck.disable(card)
 battle.deck.draw_pile.clear()
 battle.begin_adjust()
 battle.adjust_card(selected)
 verify(battle.hand[0] == selected and battle.adjust_available, "No replacement: adjustment remains available")
 battle.cancel_selection()
 verify(battle.phase == BattleState.Phase.PLAYER_ACTION, "Selection can be cancelled")
 fresh()
 var extra := give("insight")
 battle.end_turn()
 battle.choose_retain(extra)
 verify(battle.phase == BattleState.Phase.RETAIN_SELECTION, "Cannot retain temporary extra card")
 battle.choose_retain(null)
 verify(battle.extra_cards.is_empty(), "Extra cards discarded at end")
 verify_conservation()

func _test_counter() -> void:
 fresh()
 var card := give("ambush_counter", 2)
 battle.play_card(card)
 verify(battle.counter.card == card and battle.hand[2] == null, "Counter leaves hand slot empty")
 verify(battle.counter.state == BattleState.CounterState.PREPARING, "Counter initially preparing")
 verify(battle.energy == 2 and not battle.deck.discard_pile.has(card), "Counter costs energy and stays out of discard")
 pass_turn()
 verify(battle.player_hp == 25 and battle.turn_number == 2, "Preparing counter cannot interrupt same round")
 verify(battle.counter.state == BattleState.CounterState.READY, "Counter ready next player turn")
 pass_turn()
 verify(battle.turn_number == 3, "Defense intent does not open counter window")
 pass_turn()
 verify(battle.phase == BattleState.Phase.COUNTER_WINDOW, "Attack opens manual counter window")
 verify(battle.player_hp == 25 and battle.energy == 0, "Counter window pauses incoming damage")
 var enemy_hp := battle.enemy.hp
 battle.choose_counter(true)
 verify(battle.player_hp == 21, "Counter reduces attack before armor: 10 - 5 - 1")
 verify(battle.enemy.hp == enemy_hp - 4, "Counter retaliation has no attack weapon bonus")
 verify(battle.counter.card == null and battle.counter.state == BattleState.CounterState.EMPTY, "Counter consumed")
 verify_conservation()
 fresh()
 battle.play_card(give("ambush_counter", 2))
 pass_turn()
 pass_turn()
 pass_turn()
 battle.choose_counter(false)
 verify(battle.player_hp == 16 and battle.counter.state == BattleState.CounterState.READY, "Keep counter takes full attack and preserves readiness")
 verify_conservation()
 var replacement_data: CardData = load("res://resources/cards/ambush_counter.tres")
 var previous := battle.counter.card
 var replacement := CardInstance.new(replacement_data, 999)
 battle.arm_counter(replacement)
 verify(battle.deck.discard_pile.has(previous), "Replacing counter discards old counter")
 verify(battle.counter.state == BattleState.CounterState.PREPARING, "Replacement resets preparing state")

func _test_equipment_and_field() -> void:
 fresh()
 battle.play_card(give("multi_slash"))
 verify(battle.enemy.burn == 0, "Second hit does not trigger Ember Sword")
 battle.play_card(give("slash"))
 verify(battle.enemy.burn == 2, "Second attack card applies Burn 2")
 battle.play_card(give("slash"))
 verify(battle.enemy.burn == 2, "Third attack card does not trigger again")
 var hp := battle.enemy.hp
 pass_turn()
 verify(battle.enemy.hp == hp - 2 and battle.enemy.burn == 1, "Burn ticks after enemy action and decays")
 pass_turn()
 verify(battle.enemy.burn == 0 and battle.enemy.block == 4, "Burn uses damage resolver against enemy block")
 fresh()
 battle.player_block = 4
 battle.damage_player(6)
 verify(battle.player_hp == 29 and battle.player_block == 0, "Armor applied after block")
 battle.damage_player(1)
 verify(battle.player_hp == 29, "Armor cannot cause negative damage")
 var first_data := CardData.new()
 first_data.card_type = CardData.Type.SKILL
 first_data.tags = PackedStringArray(["FIELD"])
 first_data.duration_turns = 2
 var first := CardInstance.new(first_data, 1001)
 var second := CardInstance.new(first_data, 1002)
 battle.replace_field(first)
 battle.replace_field(second)
 verify(battle.field.card == second and battle.deck.discard_pile.has(first), "Field replacement discards previous")
 verify(battle.field.on_round_end() == null and battle.field.remaining_turns == 1, "Field duration decreases")
 verify(battle.field.on_round_end() == second and battle.field.card == null, "Field expiry returns card for discard")

func _test_block_lifecycle() -> void:
 fresh()
 battle.enemy_delay = 0.05
 battle.play_card(give("focus"))
 battle.play_card(give("block"))
 verify(battle.player_block == 8, "Focus + Block grants 8 shield")
 var before_start: Dictionary = {}
 battle.phase_changed.connect(func(next: BattleState.Phase) -> void:
  if next == BattleState.Phase.PLAYER_TURN_START:
   before_start["block"] = battle.player_block
   before_start["energy"] = battle.energy
   before_start["hp"] = battle.player_hp)
 battle.end_turn()
 verify(battle.phase == BattleState.Phase.RETAIN_SELECTION and battle.player_block == 8,
  "End Turn click preserves block during retain selection")
 battle.choose_retain(battle.hand[0])
 verify(battle.phase == BattleState.Phase.ENEMY_TURN and battle.player_block == 8 and battle.energy == 0,
  "Player end keeps block through delayed enemy action while clearing energy")
 await create_timer(0.1).timeout
 verify(before_start.get("block") == 2 and before_start.get("hp") == 30 and before_start.get("energy") == 0,
  "Enemy hit consumes shield first; leftover 2 survives until next player turn begins")
 verify(battle.player_block == 0 and battle.energy == 3 and battle.turn_number == 2,
  "New player turn clears remaining block then restores energy")
 verify(battle.history.find("玩家回合开始：清除剩余 2 护盾。") < battle.history.find("第 2 回合 · 能量恢复至 3。"),
  "Block expiry is logged before energy restoration")
 verify_conservation()
 for intent_index in [1, 3]:
  fresh()
  battle.enemy.intent_index = intent_index
  battle.play_card(give("block"))
  pass_turn()
  verify(battle.player_hp == 30 and battle.player_block == 0 and battle.energy == 3,
   "Unused block expires after non-attacking intent %d" % intent_index)
 fresh()
 battle.play_card(give("parry"))
 pass_turn()
 verify(battle.player_hp == 29 and battle.player_block == 0,
  "Turn transition preserves partial block: 6 damage - 4 block - 1 armor")
 for activate in [true, false]:
  fresh()
  battle.play_card(give("ambush_counter", 2))
  pass_turn()
  pass_turn()
  battle.play_card(give("block"))
  pass_turn()
  verify(battle.phase == BattleState.Phase.COUNTER_WINDOW and battle.player_block == 6 and battle.energy == 0,
   "Counter decision window retains this turn's block")
  battle.choose_counter(activate)
  verify(battle.player_hp == (25 if activate else 22) and battle.player_block == 0 and battle.energy == 3,
   "Counter choice %s respects block, armor and next-turn reset" % activate)
 fresh()
 var preserving_equipment := EquipmentData.new()
 preserving_equipment.preserve_player_block = true
 battle.equipment.slots.append(preserving_equipment)
 battle.play_card(give("focus"))
 battle.play_card(give("block"))
 pass_turn()
 verify(battle.player_hp == 30 and battle.player_block == 2 and battle.energy == 3,
  "Equipment hook can preserve remaining block without affecting damage or energy")
 pass_turn()
 verify(battle.player_block == 2, "Preservation equipment works after enemy defense")
 battle.equipment.slots.erase(preserving_equipment)
 pass_turn()
 verify(battle.player_hp == 23 and battle.player_block == 0,
  "Removing preserving equipment restores normal block expiry")
 fresh()
 battle.play_card(give("focus"))
 battle.play_card(give("block"))
 battle.enemy.hp = 2
 battle.enemy.burn = 2
 pass_turn()
 verify(battle.phase == BattleState.Phase.VICTORY and battle.player_block == 2 and battle.energy == 0,
  "Battle ending during enemy action does not start a new turn or prematurely clear block")

func _test_outcomes() -> void:
 fresh()
 for turn in 15:
  if battle.phase == BattleState.Phase.DEFEAT:
   break
  pass_turn()
 verify(battle.phase == BattleState.Phase.DEFEAT and battle.player_hp == 0, "Natural defeat")
 battle.start_battle(4)
 verify(battle.phase == BattleState.Phase.PLAYER_ACTION and battle.player_hp == 30, "Restart after defeat")
 verify(battle.turn_number == 1 and battle.enemy.hp == 35, "Restart clears turn and enemy")
 battle.enemy.hp = 1
 battle.play_card(give("slash"))
 verify(battle.phase == BattleState.Phase.VICTORY, "Card kill produces victory")
 var turn := battle.turn_number
 battle.end_turn()
 verify(battle.turn_number == turn, "Terminal state blocks actions")
 battle.start_battle(3)
 verify(battle.counter.card == null and battle.enemy.burn == 0 and battle.retained_card == null, "Restart clears persistent state")
 fresh()
 battle.play_card(give("ambush_counter", 2))
 pass_turn()
 pass_turn()
 battle.enemy.hp = 4
 pass_turn()
 var hp := battle.player_hp
 battle.choose_counter(true)
 verify(battle.phase == BattleState.Phase.VICTORY and battle.player_hp == hp, "Lethal counter cancels attack")
 fresh()
 battle.enemy.hp = 2
 battle.enemy.burn = 2
 pass_turn()
 verify(battle.phase == BattleState.Phase.VICTORY, "Burn can win battle")

func verify_conservation() -> void:
 var cards: Array[CardInstance] = []
 cards.append_array(battle.deck.draw_pile)
 cards.append_array(battle.deck.discard_pile)
 cards.append_array(battle.deck.disabled_pile)
 cards.append_array(battle.extra_cards)
 for card in battle.hand:
  if card:
   cards.append(card)
 if battle.counter.card:
  cards.append(battle.counter.card)
 if battle.field.card:
  cards.append(battle.field.card)
 verify(cards.size() == battle.deck.construction.size(), "All instances accounted for")
 var ids: Dictionary = {}
 for card in cards:
  verify(not ids.has(card.instance_id), "No duplicate instance %d" % card.instance_id)
  ids[card.instance_id] = true
 verify(battle.energy >= 0 and battle.energy <= 3, "Energy invariant")

func _test_random_battles() -> void:
 var victories := 0
 var defeats := 0
 for seed_value in 60:
  fresh(seed_value)
  var rng := RandomNumberGenerator.new()
  rng.seed = seed_value
  for step in 250:
   verify_conservation()
   if battle.phase == BattleState.Phase.VICTORY:
    victories += 1
    break
   if battle.phase == BattleState.Phase.DEFEAT:
    defeats += 1
    break
   match battle.phase:
    BattleState.Phase.PLAYER_ACTION:
     var options: Array[CardInstance] = []
     for card in battle.hand + battle.extra_cards:
      if card != null and card.data.energy_cost <= battle.energy:
       options.append(card)
     if not options.is_empty() and rng.randf() < 0.9:
      battle.play_card(options[rng.randi_range(0, options.size() - 1)])
     else:
      battle.end_turn()
    BattleState.Phase.RETAIN_SELECTION:
     battle.choose_retain(battle.hand[rng.randi_range(0, 3)])
    BattleState.Phase.COUNTER_WINDOW:
     battle.choose_counter(rng.randf() < 0.65)
  verify(battle.phase in [BattleState.Phase.VICTORY, BattleState.Phase.DEFEAT], "Random battle terminates")
 print("SIMULATED BATTLES: %d victories, %d defeats" % [victories, defeats])
