extends SceneTree
var app:CampaignUI
var first_frame:=0
func _initialize():call_deferred("run")
func click(control:Control):
 assert(control!=null)
 var p:=root.get_final_transform()*control.get_global_rect().get_center()
 var motion:=InputEventMouseMotion.new()
 motion.position=p
 root.push_input(motion)
 await process_frame
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new()
  e.button_index=MOUSE_BUTTON_LEFT
  e.position=p
  e.pressed=pressed
  root.push_input(e)
  await process_frame
func button_in(node:Node,prefix:String)->Button:
 for n in node.get_children():
  if n is Button and n.text.begins_with(prefix):return n
  var found:=button_in(n,prefix)
  if found:return found
 return null
func run():
 root.size=Vector2i(1280,720)
 first_frame=Engine.get_process_frames()
 app=load("res://scenes/campaign.tscn").instantiate()
 root.add_child(app)
 current_scene=app
 app.run_seed=1000
 await create_timer(3).timeout
 await click(button_in(app.page,"守望者"))
 await create_timer(1).timeout
 await click(button_in(app.battle_ui,"规则帮助"))
 await create_timer(2).timeout
 await click(button_in(app.battle_ui.help_overlay,"继续战斗"))
 for encounter in 3:
  var b:=app.battle_ui.battle
  for step in 900:
   if b.phase in [BattleState.Phase.VICTORY,BattleState.Phase.DEFEAT]:break
   match b.phase:
    BattleState.Phase.PLAYER_ACTION:
     var card:=TestStrategy.pick(b,"guard")
     if card:
      var view:CardView
      for n in app.battle_ui.card_layer.get_children():
       if n is CardView and n.card==card:view=n
      for n in app.battle_ui.extra_row.get_children():
       if n is CardView and n.card==card:view=n
      await click(view)
     else:await click(app.battle_ui.end_button)
     await create_timer(0.55).timeout
    BattleState.Phase.RETAIN_SELECTION:
     await click(app.battle_ui.skip_button)
     await create_timer(0.25).timeout
    BattleState.Phase.COUNTER_WINDOW:
     await create_timer(0.75).timeout
     await click(app.battle_ui.modal_primary)
     await create_timer(0.35).timeout
    _:await process_frame
  assert(b.phase==BattleState.Phase.VICTORY,"Demo must win through actual clicks")
  await create_timer(1).timeout
  await click(app.battle_ui.modal_primary)
  if encounter<2:
   await create_timer(1.5).timeout
   var chosen:CardView
   for n in app.page.get_children():
    if n is CardView and n.card.data==app.reward_cards[0]:chosen=n
   await click(chosen)
   await create_timer(0.4).timeout
   await click(button_in(app.page,app.reward_items[0].display_name))
   await create_timer(0.5).timeout
   await click(app.next_button)
  else:assert(app.screen=="result" and app.battles_won==3)
 var elapsed:=float(Engine.get_process_frames()-first_frame)/60.0
 print("CARD DEMO PLAY COMPLETE AT ",elapsed)
 while Engine.get_process_frames()-first_frame<4500:await process_frame
 print("CARD MOVIE FINISHED: ",float(Engine.get_process_frames()-first_frame)/60.0)
 quit()
