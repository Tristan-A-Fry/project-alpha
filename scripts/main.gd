extends Node2D

@onready var atmosphere_audio = $AtmosphereAudio

func _ready():
	# Make sure the audio player exists
	if not atmosphere_audio:
		print("ERROR: AtmosphereAudio node not found!")
		return
	
	# Ensure the audio stream is set to loop
	if atmosphere_audio.stream:
		if atmosphere_audio.stream is AudioStreamWAV:
			atmosphere_audio.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			print("Audio loop mode set to LOOP_FORWARD")
		
		# Connect the finished signal to restart playback (backup for continuous looping)
		# This ensures the audio restarts even if loop_mode doesn't work properly
		if not atmosphere_audio.finished.is_connected(_on_atmosphere_audio_finished):
			atmosphere_audio.finished.connect(_on_atmosphere_audio_finished)
		
		print("Audio stream configured. Playing: ", atmosphere_audio.playing)
	else:
		print("ERROR: Audio stream is null!")

func _on_atmosphere_audio_finished():
	# Immediately restart playback when audio finishes
	# This ensures continuous looping
	print("Audio finished, restarting...")
	if atmosphere_audio and atmosphere_audio.stream:
		atmosphere_audio.play()
