extends Node

onready var main_player = preload("res://Player/Player.tscn").instance()

var other_player = preload("res://Player/Player Other.tscn")

var connected = false

var ip = "127.0.0.1"

func join():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, 6969)
	get_tree().network_peer = peer
	peer.connect("connection_succeeded", self, "joined_server")
	peer.connect("connection_failed", self, "failed_connection")

func joined_server():
	connected = true
	get_node("../World").add_child(main_player)
	get_node("../World/Main menu").hide()
	rpc_id(1, "request_players")

func failed_connection():
	get_node("../World/Main menu/HBoxContainer/VBoxContainer/Join").disabled = false
	print("couldn't connect to " + ip)

remote func request_players():
	var player_id = get_tree().get_rpc_sender_id()
	var player_list = []
	player_list.append(1)
	for player in get_node("../World/Other Players").get_children():
		player_list.append(player.name)
	print(player_list)
	rpc_id(player_id, "recieve_players", player_list)

remote func recieve_players(player_list):
	print("player list " + str(player_list))
	for player in player_list:
		if get_node("../World/Other Players").has_node(str(player)):
			continue
		elif get_tree().get_network_unique_id() == int(player):
			continue
		print("creating player id " + str(player))
		var new_player = other_player.instance()
		new_player.name = str(player)
		get_node("../World/Other Players").add_child(new_player, true)

func create():
	connected = true
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(6969, 3)
	get_tree().network_peer = peer
	get_node("../World").add_child(main_player)
	get_node("../World/Main menu").hide()
	peer.connect("peer_connected", self, "player_joined")
	peer.connect("peer_disconnected", self, "player_left")

func player_joined(player_id):
	var new_player = other_player.instance()
	new_player.name = str(player_id)
	get_node("../World/Other Players").add_child(new_player, true)
	rpc_id(0, "spawn_player", player_id)
	print("player " + str(player_id) + " has joined")

func player_left(player_id):
	rpc_id(0, "despawn_player", player_id)
	if get_node("../World/Other Players").has_node(str(player_id)):
		get_node("../World/Other Players/" + str(player_id)).queue_free()
	print("player " + str(player_id) + " has left")

remote func spawn_player(player_id):
	if get_tree().get_rpc_sender_id() == 1:
		if get_tree().get_network_unique_id() == player_id:
			return
		var new_player = other_player.instance()
		new_player.name = str(player_id)
		get_node("../World/Other Players").add_child(new_player, true)

remote func despawn_player(player_id):
	if get_tree().get_rpc_sender_id() == 1:
		if get_node("../World/Other Players").has_node(str(player_id)):
			get_node("../World/Other Players/" + str(player_id)).queue_free()

func player_state(position):
	if get_tree().get_network_unique_id() == 1:
		rpc_unreliable_id(0, "recieve_player_state", 1, position)
	else:
		rpc_unreliable_id(1, "share_player_state", position)

remote func share_player_state(position):
	var player_id = get_tree().get_rpc_sender_id()
	if get_tree().get_network_unique_id() == 1:
		get_node("../World/Other Players/" + str(player_id)).global_transform.origin = position
		rpc_unreliable_id(0, "recieve_player_state", player_id, position)

remote func recieve_player_state(player_id, position):
	if get_tree().get_rpc_sender_id() == 1:
		if get_node("../World/Other Players").has_node(str(player_id)):
			get_node("../World/Other Players/" + str(player_id)).global_transform.origin = position
