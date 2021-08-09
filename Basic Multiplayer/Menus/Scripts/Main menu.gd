extends Control

func join_Button_pressed():
	$HBoxContainer/VBoxContainer/Join.disabled = true
	Server.join()

func create_button_pressed():
	Server.create()
