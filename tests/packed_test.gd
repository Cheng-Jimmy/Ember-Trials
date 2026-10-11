extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var app = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 root.add_child(app)
 current_scene = app
 if ProjectSettings.get_setting("application/config/name") == "pokegame":
  assert(load("res://scripts/cards/resource_validator.gd").catalog().size() == 16)
  app.begin_run("guard")
  assert(app.screen == "battle" and app.cards.size() == 12)
 else:
  app.begin_run()
  await physics_frame
  assert(app.screen == "playing" and app.manager.total_spawned == 2)
 await create_timer(0.2).timeout
 app.show_menu()
 await create_timer(0.65).timeout
 app.queue_free()
 await process_frame
 await process_frame
 print("PACKED GAME START AND RESTART PASSED")
 quit()


