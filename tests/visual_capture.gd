extends SceneTree
func _initialize():call_deferred("run")
func capture(folder: String,name: String):
 await create_timer(0.35).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder+"/"+name+".png")
func run():
 var folder=OS.get_cmdline_user_args()[0]
 DirAccess.make_dir_recursive_absolute(folder)
 var app=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 root.add_child(app)
 current_scene=app
 var card_game=ProjectSettings.get_setting("application/config/name")=="pokegame"
 for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=resolution
  var suffix=str(resolution.x)
  await capture(folder,"menu_"+suffix)
  if card_game:
   app.run_seed=1000
   app.begin_run("guard")
  else:
   app.begin_run()
   app.level_index=1
   app.start_level()
  await capture(folder,"battle_"+suffix)
  if card_game:
   var card_control:Control
   for node in app.battle_ui.card_layer.get_children():
    if node is Button:
     card_control=node
     break
   var motion=InputEventMouseMotion.new()
   motion.position=root.get_final_transform()*(card_control.global_position+card_control.size/2)
   root.push_input(motion)
   await capture(folder,"hover_"+suffix)
   motion.position=Vector2(10,10)
   root.push_input(motion)
  else:
   app.toggle_pause()
   await capture(folder,"pause_"+suffix)
   app.toggle_pause()
  app.show_menu()
  await process_frame
 await create_timer(0.7).timeout
 print("VISUAL CAPTURE THREE RESOLUTIONS PASSED")
 quit()


