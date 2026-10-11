extends SceneTree
var b: BattleManager
var checks := 0
func _initialize(): call_deferred("run")
func verify(value: bool, label: String) -> void:
 checks+=1
 assert(value,label)
func give(id: String) -> CardInstance:
 var card:=CardInstance.new(load("res://resources/cards/%s.tres"%id),999)
 b.extra_cards.append(card)
 return card
func fresh() -> void:
 b.start_battle(8)
 b.enemy_delay=0
func finish() -> void:
 b.end_turn()
 if b.phase==BattleState.Phase.RETAIN_SELECTION: b.choose_retain(null)
 if b.phase==BattleState.Phase.COUNTER_WINDOW: b.choose_counter(true)
func run() -> void:
 b=BattleManager.new()
 root.add_child(b)
 fresh()
 b.player_block=12
 b.play_card(give("shield_strike"))
 verify(b.enemy.hp==24 and b.player_block==12,"Shield damage is capped and does not consume shield")
 fresh()
 b.play_card(give("brace"))
 verify(b.energy==3 and b.player_block==3,"Zero-cost defense")
 b.play_card(give("bulwark"))
 verify(b.energy==1 and b.player_block==15,"Cost-two large defense")
 fresh()
 b.play_card(give("flurry"))
 verify(b.enemy.hp==23 and b.energy==1,"Four hits apply weapon per hit")
 fresh()
 b.equipment.slots[2]=load("res://resources/equipment/coal_ring.tres")
 b.play_card(give("cinder"))
 verify(b.enemy.hp==29 and b.enemy.burn==2,"Cinder damage and burn modifier")
 b.play_card(give("kindle"))
 verify(b.enemy.burn==7 and b.enemy.intent_revealed,"Kindle reveals and applies modified burn")
 fresh()
 b.play_card(give("bastion"))
 verify(b.field.card!=null and b.field.remaining_turns==3,"Field installs")
 finish()
 verify(b.field.remaining_turns==2 and b.player_block==3,"Field grants block at next start")
 finish()
 verify(b.field.remaining_turns==1 and b.player_block==3,"Field second tick")
 finish()
 verify(b.field.card==null and b.player_block==0,"Field expires into discard")
 fresh()
 b.equipment.slots[2]=load("res://resources/equipment/watch_ring.tres")
 b.play_card(give("riposte"))
 finish()
 finish()
 b.end_turn()
 if b.phase==BattleState.Phase.RETAIN_SELECTION:b.choose_retain(null)
 verify(b.phase==BattleState.Phase.COUNTER_WINDOW,"Riposte waits for attack")
 var before:=b.enemy.hp
 b.choose_counter(true)
 verify(b.enemy.hp==before-13 and b.counter.card==null,"Counter equipment adds exactly once")
 fresh()
 b.equipment.slots[1]=load("res://resources/equipment/tower_armor.tres")
 b.player_block=12
 finish()
 verify(b.player_block==6,"Tower armor preserves leftover shield")
 fresh()
 b.equipment.slots[0]=load("res://resources/equipment/duelist_blade.tres")
 b.play_card(give("flurry"))
 verify(b.enemy.hp==19,"Duelist bonus per hit")
 b.queue_free()
 await process_frame
 print("EXTENSION RULE CHECKS PASSED: ",checks)
 quit()
