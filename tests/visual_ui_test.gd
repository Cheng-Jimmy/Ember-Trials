extends SceneTree
var checks:=0
var app:CampaignUI
func _initialize():call_deferred("run")
func verify(value:bool,message:String):
 checks+=1
 if not value:
  push_error(message)
  quit(1)
  assert(value,message)
func click(control:Control):
 var motion:=InputEventMouseMotion.new()
 motion.position=root.get_final_transform()*(control.global_position+control.size/2)
 root.push_input(motion)
 await process_frame
 for state in [true,false]:
  var e:=InputEventMouseButton.new()
  e.button_index=MOUSE_BUTTON_LEFT
  e.position=motion.position
  e.pressed=state
  root.push_input(e)
  await process_frame
func capture(name:String,settle:=0.3):
 await create_timer(settle).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://outputs/"+name+".png")
func view_at(ui:BattleUI,slot:int)->CardView:
 for node in ui.card_layer.get_children():
  if node is CardView and node.card==ui.battle.hand[slot]:return node
 return null
func run():
 app=load("res://scenes/campaign.tscn").instantiate()
 root.add_child(app)
 for res in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=res
  app.run_seed=1000
  app.begin_run("guard")
  var ui:=app.battle_ui
  await capture("settled_battle_"+str(res.x))
  for slot in 4:
   var card:=view_at(ui,slot)
   var motion:=InputEventMouseMotion.new()
   motion.position=root.get_final_transform()*(card.global_position+card.size/2)
   root.push_input(motion)
   await create_timer(0.18).timeout
   verify(card.scale.is_equal_approx(Vector2(1.2,1.2)),"Physical viewport hover input")
   var r:=card.get_global_rect()
   for node in [ui.enemy_hp_bar,ui.enemy_status,ui.intent,ui.end_button,ui.counter_label,ui.field_label,ui.prompt_label]:
    verify(not r.intersects(node.get_global_rect()),"Hover preserves critical information")
   verify(card.description_label.get_theme_font_size("font_size")==24,"Large effect text")
  await capture("hover_final_"+str(res.x))
  ui.battle.end_turn()
  verify(ui.skip_button.visible,"Retain control visible")
  verify(not view_at(ui,3).get_global_rect().intersects(ui.skip_button.get_global_rect()),"Retain controls outside hover")
  await click(ui.cancel_button)
  verify(ui.battle.phase==BattleState.Phase.PLAYER_ACTION,"Cancel selection via input")
  ui._toggle_help()
  verify(ui.help_overlay.visible,"Expanded help")
  await capture("help_"+str(res.x))
  ui._toggle_help()
  await click(view_at(ui,0))
  verify(ui.card_transition_count>0,"Played-card animation hooked into actual play")
  await capture("attack_feedback_"+str(res.x),0.025)
  app.show_menu()
  await process_frame
 # Every full card fits at the real base font size; no rules are changed.
 var host:=Control.new()
 host.theme=BattleTheme.make_theme()
 root.add_child(host)
 for card_data in ResourceValidator.catalog():
  var card:=CardView.new()
  card.setup(CardInstance.new(card_data,100))
  host.add_child(card)
  await process_frame
  verify(card.description_label.position.y+card.description_label.get_minimum_size().y<=card.card_size.y-4,"No clipped description: "+card_data.id)
  host.remove_child(card)
  card.queue_free()
 host.queue_free()
 app.begin_run("guard")
 var samples:Array[float]=[]
 for i in 60:
  await process_frame
  samples.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
 var file:=FileAccess.open("res://outputs/presentation_performance.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"process_ms_mean":samples.reduce(func(a,b):return a+b,0.0)/samples.size(),"fps":Engine.get_frames_per_second()},"  "))
 file.close()
 app.show_menu()
 await create_timer(0.8).timeout
 print("CARD VISUAL CHECKS PASSED: ",checks)
 quit()

