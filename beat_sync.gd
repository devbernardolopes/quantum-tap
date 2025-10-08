class_name BeatSync

extends Node

signal beat

@export var audio_stream_player: AudioStreamPlayer
@export var beat_data_path: String = "res://Assets/Musics/cyberpunk_arcade_3_beats.json"
#@export var beat_data_path: String = "res://Assets/Musics/cyberpunkmix4_beats.json"
#cyberpunk_arcade_3_beats.json
var beats: Array = []
var beat_index: int = 0

func _ready():
	reset()

func reset() -> void:
	var file = FileAccess.open(beat_data_path, FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if typeof(json) == TYPE_DICTIONARY:
			beats = json["beats"]
	else:
		push_error("Beat data file not found at: %s" % beat_data_path)

	beat_index = 0

func _process(_delta):
	if audio_stream_player:
		if audio_stream_player.stream:
			if audio_stream_player.playing:
				if beat_index >= beats.size():
					beat_index = 0
					print("return")
					#return

				var pos = audio_stream_player.get_playback_position()
				if pos >= beats[beat_index]:
					emit_signal("beat")
					print(str(pos) + " " + str(beats[beat_index]))
					beat_index += 1
