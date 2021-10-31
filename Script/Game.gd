extends Control

var choice_button = preload("res://Prefs/Button.tscn")
var char_sprite = preload("res://Prefs/CharacterSprite.tscn")

export var _story_folder: String = "Story"
var chars: Dictionary
var branches: Dictionary
var scenes: Dictionary
var music: Dictionary

var can_click: bool = true

var curr_info = {
	"branch": "Start",
	"idx": -1,
}

signal story_loaded


# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("story_loaded", self, "_on_story_load")
	_load_story(_story_folder)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _load_story(story: String):
	var f = File.new()
	f.open("res://{0}/story.json".format([story]), File.READ)
	var data = JSON.parse(f.get_as_text()).result
	f.close()
	chars = data["chars"]
	scenes = data["scenes"]
	branches = data["storyline"]
	music = data["music"]
	emit_signal("story_loaded")

func _on_story_load():
	next_act()

func _parse_act(act):
	if act is String:
		var cmds = act.split(" ", false)
		match cmds[0]:
			"scene":
				$TextureRect.texture = load("res://{0}/Scenes/{1}".format([_story_folder, scenes[cmds[1]]]))
				next_act()
				return
			"show":
				var char_info = chars[cmds[1]]
				var character = char_sprite.instance()
				character.texture = load("res://{0}/{1}".format([_story_folder, char_info["sprite"]]))
				character.who = cmds[1]
				$CharactersContainer.add_child(character)
				next_act()
				return
			"hide":
				for c in $CharactersContainer.get_children():
					if c.who == cmds[1]:
						c.queue_free()
						break
				next_act()
				return
			"goto":
				next_branch(cmds[1])
				return
			"play":
				match cmds[1]:
					"music":
						$MusicPlayer.stream = load("res://{0}/Music/{1}".format([_story_folder, music[cmds[2]]]))
						$MusicPlayer.play()
				next_act()
				return
		if cmds[0] in chars:
			$DialogueBox/Name.set_text(chars[cmds[0]]["name"])
			cmds.remove(0)
			$DialogueBox/Text.set_text(cmds.join(" "))
		else:
			$DialogueBox/Name.set_text("")
			$DialogueBox/Text.set_text(act)
	elif act is Dictionary:
		if "Choice" in act:
			can_click = false
			for b in act["Choice"]:
				var cbutton = choice_button.instance()
				cbutton.set_text(b["Text"])
				cbutton.goto_section = b["GoTo"]
				cbutton.connect("pressed_with_node", self, "_on_choice_button_press")
				$ButtonContainer.add_child(cbutton)


func next_act():
	if curr_info["idx"] < len(branches[curr_info["branch"]])-1:
		curr_info["idx"] += 1
		_parse_act(branches[curr_info["branch"]][curr_info["idx"]])
	else:
		get_tree().quit()


func next_branch(branch: String):
	curr_info["branch"] = branch
	curr_info["idx"] = 0
	_parse_act(branches[curr_info["branch"]][curr_info["idx"]])


func _on_choice_button_press(node: Node):
	remove_buttons()
	next_branch(node.goto_section)
	can_click = true


func remove_buttons():
	for b in $ButtonContainer.get_children():
		b.queue_free()


func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					if $DialogueBox.visible and can_click:
						next_act()
				BUTTON_RIGHT:
					$DialogueBox.visible = !$DialogueBox.visible
