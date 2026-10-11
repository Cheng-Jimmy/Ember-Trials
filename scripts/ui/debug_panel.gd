class_name BattleDebugPanel
extends Panel

var output: RichTextLabel

func _ready() -> void:
 add_theme_stylebox_override("panel", BattleTheme.box(Color("101925"), BattleTheme.GOLD, 12, 2))
 var title := Label.new()
 title.text = "DEBUG / 完整内部状态"
 title.position = Vector2(20, 15)
 title.add_theme_color_override("font_color", BattleTheme.GOLD)
 add_child(title)
 var close := Button.new()
 close.text = "关闭 [F3]"
 close.position = Vector2(530, 12)
 close.size = Vector2(130, 38)
 close.pressed.connect(hide)
 add_child(close)
 output = RichTextLabel.new()
 output.position = Vector2(20, 65)
 output.size = Vector2(640, 762)
 output.add_theme_font_size_override("normal_font_size", 16)
 output.selection_enabled = true
 add_child(output)

func refresh(battle: BattleManager) -> void:
 if output == null:
  return
 var lines: Array[String] = [
  "Turn Number: %d     Battle State: %s" % [battle.turn_number, BattleState.Phase.keys()[battle.phase]],
  "Player HP: %d / 30     Player Block: %d     Energy: %d / 3" % [battle.player_hp, battle.player_block, battle.energy],
  "Draw Pile Count: %d     Discard Count: %d     Disabled Count: %d" % [battle.deck.draw_pile.size(), battle.deck.discard_pile.size(), battle.deck.disabled_pile.size()],
  "", "--- HAND / instance identity ---"]
 for slot in 4:
  lines.append("%s Slot: %s" % [["Attack", "Defense", "Skill", "Free"][slot], card_name(battle.hand[slot])])
 var extras: Array[String] = []
 for card in battle.extra_cards:
  extras.append(card_name(card))
 lines.append("Extra Card: %s" % (", ".join(extras) if not extras.is_empty() else "—"))
 lines.append("Retained Card: " + card_name(battle.retained_card))
 lines.append("Counter Card: " + card_name(battle.counter.card))
 lines.append("Counter State: %s     Armed Turn: %d" % [BattleState.CounterState.keys()[battle.counter.state], battle.counter.armed_turn])
 lines.append("Field Card: %s     Duration: %d" % [card_name(battle.field.card), battle.field.remaining_turns])
 lines.append("\n--- ENEMY / hidden information ---")
 lines.append("Enemy HP: %d / 35     Enemy Block: %d     Burn: %d" % [battle.enemy.hp, battle.enemy.block, battle.enemy.burn])
 lines.append("Enemy Intent: " + JSON.stringify(battle.enemy.current_intent().debug_data()))
 lines.append("Intent Revealed: %s     Next Attack Bonus: %d" % [battle.enemy.intent_revealed, battle.enemy.attack_bonus])
 lines.append("\n--- THIS TURN ---")
 lines.append("Attack Cards Played: %d     Defense Cards Played: %d     Skill Cards Played: %d" % battle.cards_played)
 lines.append("Adjust Available: %s     Focus Bonus: %d" % [battle.adjust_available, battle.focus_bonus])
 lines.append("\n--- RECENT BATTLE LOG ---")
 for index in range(maxi(0, battle.history.size() - 14), battle.history.size()):
  lines.append(battle.history[index])
 output.text = "\n".join(lines)

func card_name(card: CardInstance) -> String:
 return "—" if card == null else "%s #%d" % [card.data.id, card.instance_id]

