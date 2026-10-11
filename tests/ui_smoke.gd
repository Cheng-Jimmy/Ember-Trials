extends SceneTree

var ui: BattleUI
var checks: int = 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 ui = load("res://scenes/battle.tscn").instantiate()
 root.add_child(ui)
 root.size = Vector2i(1600, 900)
 ui.battle.start_battle(8)
 DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
 var ignore_file := FileAccess.open("res://tests/artifacts/.gdignore", FileAccess.WRITE)
 ignore_file.close()
 await capture("battle")
 await click(null, Vector2(1440, 458))
 verify(ui.debug_panel.visible, "Debug button opens panel")
 await capture("debug")
 await key(KEY_F3)
 verify(not ui.debug_panel.visible, "F3 closes debug")
 var hovered := view_at(2)
 await move_mouse(hovered.global_position + hovered.size / 2)
 await create_timer(0.2).timeout
 verify(hovered.scale.is_equal_approx(Vector2(1.2, 1.2)) and hovered.z_index == 20, "Card hover enlarges and raises")
 await capture("hover")
 await move_mouse(Vector2(1200, 800))
 await create_timer(0.2).timeout
 verify(hovered.scale.is_equal_approx(Vector2.ONE), "Mouse exit restores card")
 ui.battle.set_energy(0)
 await click(view_at(0))
 verify(ui.toast.text.contains("能量不足"), "Insufficient energy feedback")
 verify(ui.battle.hand[0] != null, "Failed click does not consume card")
 ui.battle.start_battle(8)
 await process_frame
 var selected := ui.battle.hand[1]
 await click(ui.adjust_button)
 verify(ui.battle.phase == BattleState.Phase.ADJUST_SELECTION, "Adjust button routes to selection")
 await click(view_at(1))
 verify(ui.battle.hand[1] != selected and ui.adjust_button.disabled, "Click adjusts card and disables button")
 await click(ui.end_button)
 verify(ui.skip_button.visible, "End turn exposes retain controls")
 await capture("retain")
 await click(ui.cancel_button)
 verify(ui.battle.phase == BattleState.Phase.PLAYER_ACTION, "Cancel restores player actions")
 await click(ui.end_button)
 selected = ui.battle.hand[2]
 await click(view_at(2))
 await create_timer(0.8).timeout
 verify(ui.battle.hand[2] == selected and ui.battle.turn_number == 2, "Click retains card into next turn")
 # Full manual counter path via card/button input in the rendered scene.
 ui.battle.start_battle(8)
 await process_frame
 await click(view_at(2))
 verify(ui.battle.counter.state == BattleState.CounterState.PREPARING, "Click arms counter")
 await finish_turn()
 verify(ui.battle.counter.state == BattleState.CounterState.READY, "Counter readies after full round")
 await finish_turn()
 await finish_turn()
 verify(ui.modal.visible and ui.battle.phase == BattleState.Phase.COUNTER_WINDOW, "Counter modal pauses attack")
 await capture("counter")
 var hp := ui.battle.player_hp
 await click(ui.modal_secondary)
 verify(ui.battle.counter.state == BattleState.CounterState.READY and ui.battle.player_hp < hp, "Keep button preserves counter")
 await finish_turn()
 await finish_turn()
 verify(ui.battle.phase == BattleState.Phase.COUNTER_WINDOW, "Next attack opens counter again")
 await click(ui.modal_primary)
 verify(ui.battle.counter.card == null, "Activate button consumes counter")
 # Normal defeat then restart through UI.
 ui.battle.start_battle(8)
 ui.battle.enemy_delay = 0.01
 for turn in 12:
  if ui.battle.phase == BattleState.Phase.DEFEAT:
   break
  await finish_turn()
 verify(ui.modal_title.text == "DEFEAT", "Defeat overlay")
 await capture("defeat")
 await click(ui.modal_primary)
 verify(ui.battle.player_hp == 30 and ui.battle.turn_number == 1, "Restart button resets battle")
 # Deterministic play-to-win using only clickable affordable cards.
 ui.battle.start_battle(8)
 for step in 100:
  if ui.battle.phase == BattleState.Phase.VICTORY:
   break
  var attack_view: CardView
  for node in ui.card_layer.get_children():
   if node is CardView and node.card.data.card_type == CardData.Type.ATTACK and node.card.data.energy_cost <= ui.battle.energy:
    attack_view = node
    break
  if attack_view:
   await click(attack_view)
  else:
   await finish_turn()
 verify(ui.battle.phase == BattleState.Phase.VICTORY, "Playable victory through card clicks")
 await capture("victory")
 await click(ui.modal_primary)
 verify(not ui.modal.visible and ui.battle.enemy.hp == 35, "Restart after victory")
 # A stale enemy timer may not damage a newly restarted battle.
 ui.battle.enemy_delay = 0.25
 ui.battle.end_turn()
 ui.battle.choose_retain(null)
 ui.battle.start_battle(8)
 await create_timer(0.4).timeout
 verify(ui.battle.player_hp == 30 and ui.battle.turn_number == 1, "Restart invalidates pending enemy timer")
 # Reveal and extra-card region through the same real card click path.
 for seed_value in 60:
  ui.battle.start_battle(seed_value)
  if ui.battle.hand[2] != null and ui.battle.hand[2].data.id == "insight":
   break
 await process_frame
 verify(ui.battle.hand[2].data.id == "insight", "Found seeded Insight hand")
 await click(view_at(2))
 verify(ui.battle.enemy.intent_revealed and ui.intent.text.contains("6"), "Insight shows full intent on UI")
 verify(ui.extra_row.get_child_count() == 1, "Extra card rendered separately")
 await capture("insight_extra")
 var extra: CardView = ui.extra_row.get_child(0)
 await move_mouse(extra.global_position + extra.size / 2)
 await create_timer(0.2).timeout
 verify(ui.extra_scroll.get_global_rect().encloses(extra.get_global_rect()), "Extra card hover remains inside scroll region")
 await capture("extra_hover")
 var previous_count := ui.battle.extra_cards.size()
 await click(extra)
 verify(ui.battle.extra_cards.size() < previous_count, "Extra card is playable by click")
 # The rendered UI must preserve defense through enemy action and reset at the next start.
 for seed_value in 120:
  ui.battle.start_battle(seed_value)
  if ui.battle.hand[2].data.id == "focus" and ui.battle.hand[1].data.id == "block":
   break
 ui.battle.enemy_delay = 1.0
 await process_frame
 await click(view_at(2))
 await click(view_at(1))
 verify(ui.battle.player_block == 8 and ui.player_status.text.contains("护盾  8"), "Defense cards display 8 block")
 await click(ui.end_button)
 verify(ui.battle.player_block == 8 and ui.skip_button.visible, "End Turn retains visible block during selection")
 await click(ui.skip_button)
 verify(ui.battle.phase == BattleState.Phase.ENEMY_TURN and ui.battle.player_block == 8 and ui.battle.energy == 0,
  "Block remains available during rendered enemy turn")
 await capture("block_enemy_turn")
 await create_timer(1.2).timeout
 verify(ui.battle.player_hp == 30 and ui.battle.player_block == 0 and ui.battle.energy == 3,
  "Enemy attack blocked; leftovers expire when new player turn starts")
 verify(ui.player_status.text.contains("护盾  0") and ui.energy_label.text == "3 / 3",
  "New turn UI displays cleared block and restored energy")
 verify(ui.debug_panel.output.text.contains("Player Block: 0"), "Debug panel reflects new-turn block expiry")
 await capture("block_next_turn")
 ui.battle.start_battle(8)
 root.size = Vector2i(1280, 720)
 await capture("battle_1280")
 print("UI INTERACTION CHECKS PASSED: %d; screenshots in tests/artifacts" % checks)
 quit()

func verify(condition: bool, label: String) -> void:
 checks += 1
 if not condition:
  push_error("UI FAILED: " + label)
  quit(1)
  assert(condition, label)

func capture(file_name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/artifacts/%s.png" % file_name)

func view_at(slot: int) -> CardView:
 for node in ui.card_layer.get_children():
  if node is CardView and node.card == ui.battle.hand[slot]:
   return node
 return null

func move_mouse(point: Vector2) -> void:
 var motion := InputEventMouseMotion.new()
 motion.position = point
 root.push_input(motion)
 await process_frame

func click(control: Control, point: Vector2 = Vector2.ZERO) -> void:
 if control:
  point = control.global_position + control.size / 2
 await move_mouse(point)
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.position = point
 event.pressed = true
 root.push_input(event)
 await process_frame
 event = event.duplicate()
 event.pressed = false
 root.push_input(event)
 await process_frame

func key(code: Key) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.pressed = true
 root.push_input(event)
 await process_frame
 event = event.duplicate()
 event.pressed = false
 root.push_input(event)
 await process_frame

func finish_turn() -> void:
 await click(ui.end_button)
 if ui.battle.phase == BattleState.Phase.RETAIN_SELECTION:
  await click(ui.skip_button)
 await create_timer(ui.battle.enemy_delay + 0.1).timeout
