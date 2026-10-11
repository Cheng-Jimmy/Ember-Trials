class_name FieldSlot
extends RefCounted

var card: CardInstance
var remaining_turns: int = -1

func replace(next: CardInstance) -> CardInstance:
 var previous := card
 card = next
 remaining_turns = next.data.duration_turns if next else -1
 return previous

func on_round_end() -> CardInstance:
 if card == null or remaining_turns < 0:
  return null
 remaining_turns -= 1
 if remaining_turns <= 0:
  return replace(null)
 return null
