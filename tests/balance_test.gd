extends SceneTree
var checks := 0
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var rows: Array[String] = ["strategy,runs,wins,win_rate,mean_turns_all_runs,mean_remaining_hp_all_runs,card_usage_json"]
 for route in ["guard","burn"]:
  var wins := 0
  var turns := 0
  var life := 0
  var uses := {}
  for seed_value in 60:
   var hp := 30
   var build := DeckDefinition.new()
   build.cards.assign(load("res://resources/decks/starter.tres").cards)
   for id in (["shield_strike","riposte"] if route=="guard" else ["cinder","kindle"]): build.cards.append(load("res://resources/cards/%s.tres"%id))
   var items: Array[EquipmentData] = [load("res://resources/equipment/ember_sword.tres"),load("res://resources/equipment/leather_armor.tres"),load("res://resources/equipment/%s.tres"%("watch_ring" if route=="guard" else "coal_ring"))]
   for encounter in 3:
    var b := BattleManager.new()
    b.configure(build,load("res://resources/enemies/%s.tres"%CampaignUI.ENEMIES[encounter]),items,hp)
    b.enemy_delay = 0
    b.start_battle(1000+seed_value+encounter)
    for step in 350:
     if b.phase in [BattleState.Phase.VICTORY,BattleState.Phase.DEFEAT]: break
     TestStrategy.step(b,route)
     checks += 1
     assert(b.energy>=0 and b.energy<=3)
    assert(b.phase in [BattleState.Phase.VICTORY,BattleState.Phase.DEFEAT])
    turns += b.turn_number
    hp = b.player_hp
    for id in b.usage: uses[id]=int(uses.get(id,0))+int(b.usage[id])
    var won := b.phase==BattleState.Phase.VICTORY
    b.free()
    if not won: break
    if encounter==2:
     wins+=1
    else:
     hp=mini(30,hp+8)
     var card_id: String = (["shield_strike","riposte"][encounter] if route=="guard" else ["cinder","flurry"][encounter])
     build.cards.append(load("res://resources/cards/%s.tres"%card_id))
     var item: EquipmentData = load("res://resources/equipment/%s.tres"%(["tower_armor","watch_ring"][encounter] if route=="guard" else ["duelist_blade","coal_ring"][encounter]))
     items[item.slot]=item
   life+=hp
  assert(wins>0)
  var row := "%s,60,%d,%.3f,%.2f,%.2f,\"%s\""%[route,wins,float(wins)/60,float(turns)/60,float(life)/60,JSON.stringify(uses).replace("\"", "\"\"")]
  print(row)
  rows.append(row)
 DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
 var file := FileAccess.open("res://tests/artifacts/balance.csv",FileAccess.WRITE)
 file.store_string("\n".join(rows))
 file.close()
 print("BALANCE CHECKS PASSED: ",checks)
 quit()
