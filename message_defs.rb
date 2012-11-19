# Client / Server Messages
# This is more of an internal tool used by the low-level socket code to inform the state management when a connection with the server dies
Message.define(:connection_reset, :socket)

# This is used by the server to inform the client that it requested information in a bad way
Message.define(:invalid_request,  :socket, [:reason])

# Login phase
Message.define(:login_request, :login, [:username])
Message.define(:login_reject,  :login, [:reason])
Message.define(:auth_request,  :login, [:hash_method,:server_hash])
Message.define(:auth_response, :login, [:password_hash])
Message.define(:auth_reject,   :login, [:reason])
Message.define(:auth_accept,   :login)

# Server Menu phase
Message.define(:get_motd,       :server_menu)
Message.define(:motd,           :server_menu, [:motd])
Message.define(:list_lobbies,   :server_menu)
Message.define(:lobby_list,     :server_menu, [:lobbies])
Message.define(:join_lobby,     :server_menu, [:lobby_name,:lobby_password])
Message.define(:join_success,   :server_menu)
Message.define(:join_fail,      :server_menu, [:reason])
Message.define(:create_lobby,   :server_menu, [:lobby_name,:lobby_password])
Message.define(:create_success, :server_menu)
Message.define(:create_fail,    :server_menu, [:reason])

# Lobby phase
# Inter-player communication
Message.define(:send_chat,           :lobby, [:chat_text])
Message.define(:send_whisper,        :lobby, [:recipient,:chat_text])
Message.define(:receive_chat,        :lobby, [:sender,:chat_text,:is_whisper])

# Game / World generation
Message.define(:get_game_params,     :lobby)                # C->S
# FIXME - Add protocol for setting game parameters
Message.define(:game_params,         :lobby, [:params])     # S->C
Message.define(:generate_game,       :lobby)                # C->S
Message.define(:generation_success,  :lobby)                # S->C
Message.define(:generation_fail,     :lobby, [:reason])     # S->C

# Character creation / selection
Message.define(:create_character,    :lobby, [:attributes])     # C->S
Message.define(:list_characters,     :lobby)                    # C->S
Message.define(:character_list,      :lobby, [:characters])     # S->C
Message.define(:select_character,    :lobby, [:character_name]) # C->S
Message.define(:character_ready,     :lobby)                    # S->C
Message.define(:character_not_ready, :lobby, [:reason])         # S->C

# Game administration and information
Message.define(:start_game,          :lobby)                # C->S
Message.define(:start_success,       :lobby)                # S->C
Message.define(:start_fail,          :lobby, [:reason])     # S->C
Message.define(:toggle_pause,        :lobby)                # C->S
Message.define(:pause_state,         :lobby)                # S->C

Message.define(:user_joins,          :lobby, [:username])   # S->C
Message.define(:user_leaves,         :lobby, [:username])   # S->C
Message.define(:admin_change,        :lobby, [:admin])      # S->C

# Gameplay
Message.define(:query_location, :game)
Message.define(:location,       :game, [:zone, :area])

# Client / Interface Messages
# Interface Messages
# This group is a special class of messages which are used by the state to perform interactions
Message.define(:text_field,       :prompt)
Message.define(:choose_from_list, :prompt,   [:choices])
Message.define(:valid_input,      :response, [:input])
Message.define(:invalid_input,    :response)

# Mostly just raw text messages
Message.define(:notify,         :interface, [:text])
Message.define(:list,           :interface, [:title,:items])
Message.define(:properties,     :interface, [:title,:hash])
Message.define(:raw_command,    :interface, [:command])
