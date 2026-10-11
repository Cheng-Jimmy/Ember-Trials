class_name BattleEnemy
extends RefCounted

var data: EnemyData
var hp: int
var block: int = 0
var burn: int = 0
var attack_bonus: int = 0
var intent_index: int = 0
var intent_revealed: bool = false

func _init(definition: EnemyData = null) -> void:
 data = definition
 if data:
  hp = data.max_hp

func current_intent() -> EnemyIntent:
 return data.intents[intent_index]

func advance_intent() -> void:
 intent_index = (intent_index + 1) % data.intents.size()
 intent_revealed = false
