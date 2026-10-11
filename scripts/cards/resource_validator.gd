class_name ResourceValidator
extends RefCounted
const OPS := ["damage", "block", "reveal", "draw", "focus", "counter", "field", "burn", "shield_strike"]
static func validate_cards(cards: Array[CardData]) -> PackedStringArray:
 var errors := PackedStringArray()
 var seen := {}
 for card in cards:
  if card == null:
   errors.append("空卡牌资源")
   continue
  if card.id.is_empty() or seen.has(card.id): errors.append("重复或空 ID: " + card.id)
  seen[card.id] = true
  if card.card_type < 0 or card.card_type > 2: errors.append(card.id + ": 非法类别")
  if card.energy_cost < 0 or card.energy_cost > 3 or card.base_value < 0: errors.append(card.id + ": 非法费用或数值")
  if card.display_name.is_empty() or card.description.is_empty() or card.effect_data.is_empty(): errors.append(card.id + ": 缺少描述或效果")
  var persistent := 0
  for effect in card.effect_data:
   var op := str(effect.get("op", ""))
   if not OPS.has(op): errors.append(card.id + ": 未知效果 " + op)
   for key in effect:
    if key != "op" and (not (effect[key] is int or effect[key] is float) or effect[key] < 0): errors.append(card.id + ": 非法效果参数 " + str(key))
   if int(effect.get("hits", 1)) < 1: errors.append(card.id + ": 命中次数必须为正")
   if op in ["counter", "field"]:
    persistent += 1
    if not card.tags.has(op.to_upper()): errors.append(card.id + ": 缺少持久槽标签")
  if persistent > 1: errors.append(card.id + ": 多个持久槽效果")
  if card.tags.has("FIELD") and card.duration_turns != -1 and card.duration_turns <= 0: errors.append(card.id + ": 非法场地持续时间")
 return errors
static func catalog() -> Array[CardData]:
 var cards: Array[CardData] = []
 var files := DirAccess.get_files_at("res://resources/cards")
 for file in files:
  if file.ends_with(".tres") or file.ends_with(".tres.remap"): cards.append(load("res://resources/cards/" + file.trim_suffix(".remap")))
 return cards
