class_name DamageResolver
extends RefCounted

# Every hit uses this same pipeline. Armor applies only to HP spillover.
static func resolve(base: int, block: int, card_modifier: int = 0,
  temporary_modifier: int = 0, equipment_modifier: int = 0,
  target_modifier: int = 0, hp_reduction: int = 0) -> Dictionary:
 var damage := maxi(0, base + card_modifier + temporary_modifier + equipment_modifier + target_modifier)
 var absorbed := mini(maxi(0, block), damage)
 return {"damage": damage, "absorbed": absorbed,
  "block": maxi(0, block - absorbed),
  "hp_damage": maxi(0, damage - absorbed - hp_reduction)}
