class_name TestStrategy
extends RefCounted
static func pick(b: BattleManager, route: String) -> CardInstance:
 var best: CardInstance
 var best_score := -1000.0
 var threatening := b.enemy.current_intent().category in [EnemyIntent.Category.ATTACK, EnemyIntent.Category.DANGER]
 var needed := b.enemy.current_intent().damage * b.enemy.current_intent().hits + b.enemy.attack_bonus * b.enemy.current_intent().hits - b.player_block - b.equipment.hp_reduction() * b.enemy.current_intent().hits
 for card in b.hand + b.extra_cards:
  if card == null or card.data.energy_cost > b.energy: continue
  var score := 1.0
  if card.data.card_type == CardData.Type.ATTACK: score = 5.0 if route == "guard" else 8.0
  if card.data.id == "shield_strike": score = 6.0 + b.player_block
  if card.data.id in ["block", "parry", "brace", "bulwark"]:
   score = (20.0 if route == "guard" else 12.0) if threatening and needed > 0 else (8.0 if route == "guard" and not b.equipment.clears_block() and b.player_block < 10 else -5.0)
   if route == "burn": score -= 4.0
  if card.data.id in ["focus"]: score = 10.0 if b.energy >= 2 else -3.0
  if card.data.id == "kindle": score = 11.0 if route == "burn" else 5.0
  if card.data.id == "cinder": score = 10.0
  if card.data.id == "flurry": score = 9.0
  if card.data.tags.has("COUNTER"): score = (11.0 if route == "guard" else 4.0) if b.counter.card == null else -5.0
  if card.data.tags.has("FIELD"): score = 10.0 if b.field.card == null and b.turn_number < 4 else -5.0
  if card.data.id == "insight": score = 3.0
  if score > best_score:
   best = card
   best_score = score
 return best if best_score > 0.0 else null
static func step(b: BattleManager, route: String) -> void:
 match b.phase:
  BattleState.Phase.PLAYER_ACTION:
   var card := pick(b, route)
   if card: b.play_card(card)
   else: b.end_turn()
  BattleState.Phase.RETAIN_SELECTION:
   var card: CardInstance
   for candidate in b.hand:
    if candidate and (candidate.data.id in ["bulwark", "shield_strike", "flurry", "riposte"]): card = candidate
   b.choose_retain(card)
  BattleState.Phase.COUNTER_WINDOW: b.choose_counter(true)
