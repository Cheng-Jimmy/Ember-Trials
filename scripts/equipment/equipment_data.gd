class_name EquipmentData
extends Resource

enum Slot { WEAPON, ARMOR, ACCESSORY }
@export var id: String = ""
@export var display_name: String = ""
@export var slot: Slot = Slot.WEAPON
@export_multiline var description: String = ""
@export var attack_hit_bonus: int = 0
@export var hp_damage_reduction: int = 0
@export var attack_card_trigger: int = 0
@export var burn_on_trigger: int = 0
@export var counter_damage_bonus: int = 0
@export var applied_burn_bonus: int = 0
@export var preserve_player_block: bool = false
