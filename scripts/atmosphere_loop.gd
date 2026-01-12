extends Node

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# Ensure stream is not paused
	audio_stream_player.stream_paused = false
	
	# Connect finished signal to restart playback for continuous looping
	audio_stream_player.finished.connect(_on_finished)

func _on_finished():
	# Restart playback when finished for continuous looping
	if audio_stream_player:
		audio_stream_player.play()

func _process(_delta: float) -> void:
	# Backup: if somehow it stops playing, restart it
	if audio_stream_player:
		if not audio_stream_player.playing and not audio_stream_player.stream_paused:
			audio_stream_player.play()