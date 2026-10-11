class_name BattleEquipment
extends RefCounted

var slots: Array[EquipmentData] = []

func attack_bonus() -> int:
 var total := 0
 for item in slots:
  total += item.attack_hit_bonus
 return total

func hp_reduction() -> int:
 var total := 0
 for item in slots:
  total += item.hp_damage_reduction
 return total

func triggered_burn(attack_cards: int) -> int:
 var total := 0
 for item in slots:
  if item.attack_card_trigger > 0 and attack_cards == item.attack_card_trigger:
   total += item.burn_on_trigger
 return total

func clears_block() -> bool:
 for item in slots:
  if item.preserve_player_block:
   return false
 return true

func counter_bonus() -> int:
 var total := 0
 for item in slots:
  total += item.counter_damage_bonus
 return total
func burn_bonus() -> int:
 var total := 0
 for item in slots:
  total += item.applied_burn_bonus
 return total
