# Client / Server Messages
# This is more of an internal tool used by the low-level socket code to inform the state management when a connection with the server dies
Message.define(:connection_reset, :socket, [],        "The connection was reset")
Message.define(:invalid_packet,   :socket, [:reason], "Unexpected message")
Message.define(:heartbeat,        :socket)

# Login phase
Message.define(:login_request, :login, [:username])
Message.define(:login_reject,  :login, [:reason], "Username rejected")
Message.define(:auth_request,  :login, [:hash_method,:server_hash])
Message.define(:auth_response, :login, [:password_hash])
Message.define(:auth_reject,   :login, [:reason], "Credentials rejected")
Message.define(:auth_accept,   :login, [],        "Credentials accepted")

# Server Menu phase
Message.define(:get_motd,       :server_menu)
Message.define(:motd,           :server_menu, [:text])
Message.define(:list_lobbies,   :server_menu)
Message.define(:lobby_list,     :server_menu, [:lobbies])
Message.define(:join_lobby,     :server_menu, [:lobby_name,:lobby_password])
Message.define(:join_success,   :server_menu, [],        "Lobby joined")
Message.define(:join_fail,      :server_menu, [:reason], "Failed to join lobby")
Message.define(:leave_lobby,    :server_menu)
Message.define(:create_lobby,   :server_menu, [:lobby_name,:lobby_password])
Message.define(:create_success, :server_menu, [],        "Lobby created")
Message.define(:create_fail,    :server_menu, [:reason], "Failed to create lobby")

# Inter-player communication
Message.define(:send_chat,           :chat, [:chat_text])
Message.define(:send_whisper,        :chat, [:recipient,:chat_text])
Message.define(:receive_chat,        :chat, [:sender,:chat_text,:is_whisper])

# Lobby phase
# Game / World generation
Message.define(:get_game_params,     :lobby)                                                # C->S
# TODO - Add protocol for setting game parameters
Message.define(:game_params,         :lobby, [:params])                                     # S->C
Message.define(:generate_game,       :lobby)                                                # C->S
Message.define(:generation_success,  :lobby, [],        "World generated")                  # S->C
Message.define(:generation_fail,     :lobby, [:reason], "World failed to generate")         # S->C

# Character creation / selection
Message.define(:create_character,    :lobby, [:attributes])                                 # C->S
Message.define(:get_character_opts,  :lobby, [:property])
Message.define(:character_opts,      :lobby, [:options])
Message.define(:list_characters,     :lobby)                                                # C->S
Message.define(:no_characters,       :lobby, [:reason], "No characters available")          # S->C
Message.define(:character_list,      :lobby, [:characters])                                 # S->C
Message.define(:select_character,    :lobby, [:character_name])                             # C->S
Message.define(:character_ready,     :lobby, [],        "Character ready")                  # S->C
Message.define(:character_not_ready, :lobby, [:reason], "Character not ready")              # S->C
Message.define(:begin_playing,       :lobby, [],        "Begin playing")                    # S->C

# Game administration and information
Message.define(:start_game,          :lobby)                                                # C->S
Message.define(:start_success,       :lobby, [],        "Game started")                     # S->C
Message.define(:start_fail,          :lobby, [:reason], "Failed to start game")             # S->C
#Message.define(:toggle_pause,        :lobby)                                               # C->S
#Message.define(:pause_state,         :lobby)                                               # S->C

Message.define(:user_joins,          :lobby, [:result], "User joins")                       # S->C
Message.define(:user_leaves,         :lobby, [:result], "User leaves")                      # S->C
Message.define(:admin_change,        :lobby, [:result], "Admin changed")                    # S->C

# Gameplay Protocol
# Interactions between a client and the game lobby
Message.define(:act,           :game, [:command])
Message.define(:act_clarify,   :game, [:text])
Message.define(:clarification, :game, [:command])
Message.define(:act_fail,      :game, [:reason], "Failed to perform action")
Message.define(:act_success,   :game, [:description])
Message.define(:game_event,    :game, [:description])
Message.define(:user_dies,     :game, [:result], "User dies")
Message.define(:get_link,      :game)
Message.define(:link,          :game, [:uri])

# Core Game Information
# Messages passed between the game lobby / game objects / lobby
Message.define(:tick,             :core)
Message.define(:unit_moves,       :core, [:unit, :start, :finish])
Message.define(:unit_attacks,     :core, [:attacker, :defender, :chance_to_hit, :damage])
Message.define(:unit_acts,        :core, [:agent, :target, :position])
Message.define(:object_destroyed, :core, [:agent, :target, :position])

# Client / Interface Messages
# Interface Messages
# This group is a special class of messages which are used by the state to perform interactions
Message.define(:text_field,       :prompt,   [:field])
Message.define(:choose_from_list, :prompt,   [:field, :choices])
Message.define(:valid_input,      :response, [:input])
Message.define(:invalid_input,    :response)

# Mostly just raw text messages
Message.define(:list,           :interface, [:field, :items])
Message.define(:properties,     :interface, [:field, :properties])
Message.define(:raw_command,    :interface, [:command])
