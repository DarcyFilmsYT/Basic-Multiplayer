extends Node

var player_puppet = preload("res://Player/PlayerPuppet.tscn")

var connected = false

var ip = "127.0.0.1"

func join():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, 6969)
	get_tree().network_peer = peer
	peer.connect("connection_succeeded", self, "joined_server")
	peer.connect("connection_failed", self, "failed_connection")
	peer.connect("server_disconnected", self, "host_left")

func joined_server():
	connected = true
	get_tree().change_scene("res://World.tscn")
	rpc_id(1, "request_players")

func failed_connection():
	print("BRUH? I guess 6969 was not cool enough.")

func host_left():
	get_tree().change_scene("res://Menus/Menu.tscn")
	get_tree().network_peer = null

func create():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(6969, 3)
	get_tree().network_peer = peer
	peer.connect("peer_connected", self, "player_joined")
	peer.connect("peer_disconnected", self, "player_left")
	connected = true
	get_tree().change_scene("res://World.tscn")

remote func request_players():
	if get_tree().get_network_unique_id() != 1:
		return
	var player_id = get_tree().get_rpc_sender_id()
	var player_list = []
	player_list.append(1)
	for player in get_node("../World/OtherPlayers").get_children():
		player_list.append(player.name)
	print(player_list)
	rpc_id(player_id, "recieve_players", player_list)

remote func recieve_players(player_list):
	if get_tree().get_rpc_sender_id() != 1:
		return
	for player in player_list:
		if get_node("../World/OtherPlayers").has_node(str(player)):
			continue
		elif get_tree().get_network_unique_id() == int(player):
			continue
		var new_player = player_puppet.instance()
		new_player.name = str(player)
		get_node("../World/OtherPlayers").add_child(new_player, true)

func player_joined(player_id):
	var new_player = player_puppet.instance()
	new_player.name = str(player_id)
	get_node("../World/OtherPlayers").add_child(new_player, true)

func player_left(player_id):
	if get_node("../World/OtherPlayers").has_node(str(player_id)):
		get_node("../World/OtherPlayers/" + str(player_id)).queue_free()

func export_player_state(player_state):
	if get_tree().get_network_unique_id() == 1:
		rpc_unreliable_id(0, "recieve_player_state", 1, player_state)
	else:
		rpc_unreliable_id(1, "share_player_state", player_state)

remote func share_player_state(player_state):
	if get_tree().get_network_unique_id() == 1:
		var player_id = get_tree().get_rpc_sender_id()
		get_node("../World/OtherPlayers/" + str(player_id)).global_transform.origin = player_state
		rpc_unreliable_id(0, "recieve_player_state", player_id, player_state)

remote func recieve_player_state(player_id, player_state):
	if get_tree().get_rpc_sender_id() == 1:
		if get_node("../World/OtherPlayers").has_node(str(player_id)):
			get_node("../World/OtherPlayers/" + str(player_id)).global_transform.origin = player_state
