class_name CardInstance
extends RefCounted

var data: CardData
var instance_id: int
var damage_modifier: int = 0

func _init(card_data: CardData = null, unique_id: int = 0) -> void:
 data = card_data
 instance_id = unique_id
