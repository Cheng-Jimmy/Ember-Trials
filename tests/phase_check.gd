extends SceneTree

func _initialize() -> void:
 var definitions: Array[String] = [
  "res://resources/decks/starter.tres", "res://resources/enemies/green_slime.tres",
  "res://resources/equipment/ember_sword.tres", "res://resources/equipment/leather_armor.tres",
  "res://resources/equipment/ruby_ring.tres"]
 for path in definitions:
  assert(load(path) != null, "Missing resource: " + path)
 var deck := DeckManager.new()
 deck.setup(load(definitions[0]), 42)
 assert(deck.construction.size() == 10)
 for slot in 4:
  var card := deck.draw_for_slot(slot)
  assert(card != null)
  if slot < 3:
   assert(card.data.card_type == slot)
 assert(deck.draw_pile.size() == 6)
 var result := DamageResolver.resolve(6, 4, 0, 0, 0, 0, 1)
 assert(result.hp_damage == 1 and result.block == 0)
 assert(DamageResolver.resolve(3, 0, 0, 0, 1).hp_damage == 4)
 print("PHASE CHECK PASSED: resources, four slots, deck count, damage / block / armor")
 quit()
