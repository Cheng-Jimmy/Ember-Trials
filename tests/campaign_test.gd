extends SceneTree
var checks := 0
func verify(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  push_error(message)
  quit(1)
  assert(condition, message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 verify(ResourceValidator.validate_cards(ResourceValidator.catalog()).is_empty(), "Catalog validation")
 var bad := CardData.new()
 bad.id = "bad"
 bad.effect_data = [{"op":"not_real"}]
 verify(not ResourceValidator.validate_cards([bad, bad]).is_empty(), "Invalid resource rejected")
 var rows: Array[String] = ["strategy,runs,wins,win_rate,mean_turns,mean_remaining_hp,card_usage"]
 for route in ["guard", "burn"]:
  var wins := 0
  var turns := 0
  var life := 0
  var uses := {}
  for seed_value in 3:
   var app: CampaignUI = load("res://scenes/campaign.tscn").instantiate()
   root.add_child(app)
   app.run_seed = 1000 + seed_value
   app.begin_run(route)
   verify(app.cards.size() == 12 and app.screen == "battle", "Menu starts build")
   for encounter in 3:
    var b := app.battle_ui.battle
    b.enemy_delay = 0
    for step in 350:
     if b.phase in [BattleState.Phase.VICTORY, BattleState.Phase.DEFEAT]: break
     TestStrategy.step(b, route)
     verify(b.energy >= 0 and b.energy <= 3, "Energy invariant")
     var count := b.deck.draw_pile.size() + b.deck.discard_pile.size() + b.deck.disabled_pile.size() + b.extra_cards.size()
     for card in b.hand:
      if card: count += 1
     if b.counter.card: count += 1
     if b.field.card: count += 1
     verify(count == b.deck.construction.size(), "Campaign instance conservation")
    verify(b.phase in [BattleState.Phase.VICTORY, BattleState.Phase.DEFEAT], "No deadlock")
    for id in b.usage: uses[id] = int(uses.get(id, 0)) + int(b.usage[id])
    var won := b.phase == BattleState.Phase.VICTORY
    app.finish_encounter(won)
    if not won: break
    if encounter < 2:
     verify(app.screen == "reward", "Reward screen")
     var before := app.cards.size()
     app.accept_rewards()
     verify(app.screen == "reward", "Cannot skip required choices")
     app.choose_card(app.reward_cards[0] if route == "guard" else app.reward_cards[2])
     app.choose_item(app.reward_items[0] if route == "guard" else app.reward_items[1])
     app.accept_rewards()
     verify(app.cards.size() == before + 1 and app.battle_ui.battle.deck.construction.size() == before + 1, "Reward reaches next battle")
    else: wins += 1
   verify(app.screen == "result", "Final result")
   turns += app.total_turns
   life += app.hp
   app.show_menu()
   app.begin_run(route)
   verify(app.cards.size() == 12 and app.hp == 30 and app.choices.is_empty(), "Clean restart")
   root.remove_child(app)
   app.queue_free()
   await process_frame
  verify(wins > 0, "Route can complete three battles")
  var row := "%s,3,%d,%.3f,%.2f,%.2f,%s" % [route, wins, float(wins)/3, float(turns)/3, float(life)/3, JSON.stringify(uses)]
  rows.append(row)
  print(row)
 DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
 var file := FileAccess.open("res://tests/artifacts/balance.csv", FileAccess.WRITE)
 file.store_string("\n".join(rows))
 await create_timer(0.9).timeout
 print("CAMPAIGN CHECKS PASSED: ", checks)
 quit()
