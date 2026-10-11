class_name EffectResolver
extends RefCounted

# Data selects operations; the UI never implements individual card rules.
static func apply(battle: BattleManager, card: CardInstance, temporary_bonus: int) -> void:
 for effect in card.data.effect_data:
  match String(effect.get("op", "")):
   "damage":
    for hit in int(effect.get("hits", 1)):
     battle.damage_enemy(card.data.base_value, card.damage_modifier,
      temporary_bonus, battle.equipment.attack_bonus())
     if battle.enemy.hp <= 0:
      break
   "burn":
    battle.enemy.burn += int(effect.get("amount", 0)) + battle.equipment.burn_bonus()
    battle.visual_event.emit("burn", int(effect.get("amount", 0)))
   "shield_strike":
    battle.damage_enemy(card.data.base_value + mini(battle.player_block, int(effect.get("cap", 8))), 0, temporary_bonus, battle.equipment.attack_bonus())
   "block":
    var bonus := 0
    if battle.cards_played[CardData.Type.ATTACK] > 0:
     bonus = int(effect.get("after_attack_bonus", 0))
    battle.player_block += card.data.base_value + temporary_bonus + bonus
    battle.record("获得 %d 护盾。" % (card.data.base_value + temporary_bonus + bonus))
   "reveal":
    battle.reveal_current_intent()
   "draw":
    for count in int(effect.get("count", 1)):
     var extra := battle.deck.draw_random()
     if extra:
      battle.extra_cards.append(extra)
   "focus":
    battle.focus_bonus = card.data.base_value
   "counter":
    battle.arm_counter(card)
   "field":
    battle.replace_field(card)
   _:
    push_error("Unknown card effect: %s" % effect)
