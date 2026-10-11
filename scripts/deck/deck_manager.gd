class_name DeckManager
extends RefCounted

const SLOT_TYPES: Array[int] = [CardData.Type.ATTACK, CardData.Type.DEFENSE, CardData.Type.SKILL, -1]
var construction: Array[CardInstance] = []
var draw_pile: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var disabled_pile: Array[CardInstance] = []
var rng := RandomNumberGenerator.new()

func setup(definition: DeckDefinition, random_seed: int = -1) -> void:
 construction.clear()
 draw_pile.clear()
 discard_pile.clear()
 disabled_pile.clear()
 if random_seed < 0:
  rng.randomize()
 else:
  rng.seed = random_seed
 for index in definition.cards.size():
  var instance := CardInstance.new(definition.cards[index], index + 1)
  construction.append(instance)
  draw_pile.append(instance)
 _shuffle()

func slot_type(slot: int) -> int:
 var requested := SLOT_TYPES[slot]
 if requested == -1:
  return -1
 for card in construction:
  if card.data.card_type == requested:
   return requested
 return -1

func draw_for_slot(slot: int) -> CardInstance:
 var requested := slot_type(slot)
 if requested == -1:
  return draw_random()
 var index := _find_type(requested)
 if index == -1:
  _recycle()
  index = _find_type(requested)
 if index == -1:
  # A type still in the build may be in hand, counter, field or disabled.
  # Keep this slot empty rather than silently converting it to FREE.
  return null
 return draw_pile.pop_at(index)

func draw_random() -> CardInstance:
 if draw_pile.is_empty():
  _recycle()
 if draw_pile.is_empty():
  return null
 return draw_pile.pop_at(rng.randi_range(0, draw_pile.size() - 1))

func discard(card: CardInstance) -> void:
 if card != null:
  discard_pile.append(card)

func disable(card: CardInstance) -> void:
 if card != null:
  disabled_pile.append(card)

func _find_type(requested: int) -> int:
 for index in draw_pile.size():
  if draw_pile[index].data.card_type == requested:
   return index
 return -1

func _recycle() -> void:
 draw_pile.append_array(discard_pile)
 discard_pile.clear()
 _shuffle()

func _shuffle() -> void:
 for index in range(draw_pile.size() - 1, 0, -1):
  var other := rng.randi_range(0, index)
  var temporary := draw_pile[index]
  draw_pile[index] = draw_pile[other]
  draw_pile[other] = temporary
