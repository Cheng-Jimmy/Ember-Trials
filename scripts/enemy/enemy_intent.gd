class_name EnemyIntent
extends Resource

enum Category { ATTACK, DEFENSE, SPECIAL, DANGER }

@export var category: Category = Category.ATTACK
@export var display_name: String = ""
@export var cleanse: int = 0
@export var damage: int = 0
@export var hits: int = 1
@export var block: int = 0
@export var next_attack_bonus: int = 0

func describe(bonus: int = 0) -> String:
 match category:
  Category.ATTACK, Category.DANGER:
   return "%s\n造成 %d 伤害 × %d" % [display_name, damage + bonus, hits]
  Category.DEFENSE:
   return "%s\n获得 %d 护盾%s" % [display_name, block, " · 移除 %d 灼烧" % cleanse if cleanse > 0 else ""]
  _:
   return "%s\n下次攻击 +%d 伤害" % [display_name, next_attack_bonus]

func debug_data() -> Dictionary:
 return {"category": Category.keys()[category], "name": display_name,
  "damage": damage, "hits": hits, "block": block,
  "next_attack_bonus": next_attack_bonus}
