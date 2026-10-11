class_name CardData
extends Resource

enum Type { ATTACK, DEFENSE, SKILL }

@export var id: String = ""
@export var display_name: String = ""
@export var card_type: Type = Type.ATTACK
@export_range(0, 3) var energy_cost: int = 1
@export_multiline var description: String = ""
@export var base_value: int = 0
@export var tags: PackedStringArray = []
@export var effect_data: Array[Dictionary] = []
@export var duration_turns: int = -1
