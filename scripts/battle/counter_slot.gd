class_name CounterSlot
extends RefCounted

var card: CardInstance
var state: BattleState.CounterState = BattleState.CounterState.EMPTY
var armed_turn: int = -1

func replace(next: CardInstance, turn: int) -> CardInstance:
 var previous := card
 card = next
 armed_turn = turn
 state = BattleState.CounterState.PREPARING
 return previous

func on_player_turn_start(turn: int) -> void:
 if card and turn > armed_turn:
  state = BattleState.CounterState.READY

func consume() -> CardInstance:
 var previous := card
 card = null
 state = BattleState.CounterState.EMPTY
 armed_turn = -1
 return previous

func effect_data() -> Dictionary:
 if card:
  for effect in card.data.effect_data:
   if effect.get("op") == "counter":
    return effect
 return {}
