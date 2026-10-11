extends SceneTree
var app: CampaignUI
var checks := 0
func _initialize() -> void:
 call_deferred("run")
func verify(condition: bool, message: String) -> void:
 checks+=1
 if not condition:
  push_error(message)
  quit(1)
  assert(condition,message)
func click(control: Control) -> void:
 var point := control.global_position + control.size * control.scale / 2
 var motion := InputEventMouseMotion.new()
 motion.position=point
 root.push_input(motion)
 await process_frame
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index=MOUSE_BUTTON_LEFT
  event.position=point
  event.pressed=pressed
  root.push_input(event)
  await process_frame
func find_button(text: String) -> Button:
 for node in app.page.get_children():
  if node is Button and node.text.begins_with(text): return node
 return null
func capture(name: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://outputs/"+name+".png")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://outputs")
 app=load("res://scenes/campaign.tscn").instantiate()
 root.add_child(app)
 root.size=Vector2i(1600,900)
 await capture("menu")
 for route in ["guard","burn"]:
  app.run_seed=1000
  await click(find_button("守望者" if route=="guard" else "余烬行者"))
  verify(app.screen=="battle","Start via menu click")
  for encounter in 3:
   var b:=app.battle_ui.battle
   b.enemy_delay=0.01
   await capture("%s_battle_%d"%[route,encounter+1])
   for step in 900:
    if b.phase in [BattleState.Phase.VICTORY,BattleState.Phase.DEFEAT]: break
    match b.phase:
     BattleState.Phase.PLAYER_ACTION:
      var card:=TestStrategy.pick(b,route)
      if card:
       var view: CardView
       for node in app.battle_ui.card_layer.get_children():
        if node is CardView and node.card==card: view=node
       for node in app.battle_ui.extra_row.get_children():
        if node is CardView and node.card==card: view=node
       verify(view!=null,"Playable card has control")
       await click(view)
      else: await click(app.battle_ui.end_button)
     BattleState.Phase.RETAIN_SELECTION: await click(app.battle_ui.skip_button)
     BattleState.Phase.COUNTER_WINDOW:
      await capture("counter_"+route)
      await click(app.battle_ui.modal_primary)
     _: await process_frame
   verify(b.phase==BattleState.Phase.VICTORY,"Natural victory via card clicks")
   await click(app.battle_ui.modal_primary)
   if encounter<2:
    verify(app.screen=="reward","Victory enters rewards")
    await capture("reward_"+str(encounter+1))
    var chosen: CardView
    var card:=app.reward_cards[0] if route=="guard" else app.reward_cards[2]
    for node in app.page.get_children():
     if node is CardView and node.card.data==card: chosen=node
    await click(chosen)
    var item:=app.reward_items[0] if route=="guard" else app.reward_items[1]
    await click(find_button(item.display_name))
    verify(not app.next_button.disabled,"Two choices enable next battle")
    await click(app.next_button)
    verify(app.screen=="battle" and app.cards.size()==13+encounter,"Rewards persist")
   else:
    verify(app.screen=="result" and app.battles_won==3,"Three-battle completion")
    await capture("result_"+route)
  await click(find_button("再次挑战"))
  verify(app.screen=="battle" and app.cards.size()==12,"Restart clears rewards")
  app.show_menu()
  await process_frame
 # Window-size verification uses a real rendered battle at 1920 and 1280.
 app.begin_run("burn")
 root.size=Vector2i(1920,1080)
 await capture("battle_1920")
 root.size=Vector2i(1280,720)
 await capture("battle_1280")
 app.show_menu()
 await create_timer(0.8).timeout
 print("CAMPAIGN REAL INPUT CHECKS PASSED: ",checks)
 quit()
