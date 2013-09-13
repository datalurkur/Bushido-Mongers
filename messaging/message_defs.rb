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

# Inter-player communication
Message.define(:send_chat,           :chat, [:chat_text])
Message.define(:send_whisper,        :chat, [:recipient,:chat_text])
Message.define(:receive_chat,        :chat, [:sender,:chat_text,:is_whisper])

# Lobby phase
Message.define(:access_denied,       :lobby)                                                # S->C

# Game / World loading / saving
Message.define(:get_saved_worlds,    :lobby)                                                # C->S
Message.define(:saved_worlds_info,   :lobby, [:info_hash])                                  # S->C
Message.define(:load_world,          :lobby, [:uid])                                        # C->S
Message.define(:load_pending,        :lobby, [],        "World loading in progress")        # S->C
Message.define(:load_success,        :lobby, [],        "World loaded")                     # S->C
Message.define(:load_fail,           :lobby, [:reason], "World failed to load")             # S->C
Message.define(:save_world,          :lobby)                                                # C->S
Message.define(:save_pending,        :lobby, [],        "World saving in progress")         # S->C
Message.define(:save_success,        :lobby, [],        "World saved")                      # S->C
Message.define(:save_fail,           :lobby, [:reason], "World failed to save")             # S->C

# Game / World generation
Message.define(:get_game_params,     :lobby)                                                # C->S
# TODO - Add protocol for setting game parameters
Message.define(:game_params,         :lobby, [:params])                                     # S->C
Message.define(:generate_game,       :lobby)                                                # C->S
Message.define(:generation_pending,  :lobby, [],        "World generation in progress")     # S->C
Message.define(:generation_success,  :lobby, [],        "World generated")                  # S->C
Message.define(:generation_fail,     :lobby, [:reason], "World failed to generate")         # S->C

# Character creation / selection
Message.define(:create_character,    :lobby)                                                # C->S
Message.define(:get_character_opts,  :lobby, [:property])                                   # C->S
Message.define(:character_opts,      :lobby, [:options])                                    # S->C
Message.define(:opts_unavailable,    :lobby, [:reason], "Options unavailable")              # S->C
Message.define(:set_character_opt,   :lobby, [:property, :value])                           # C->S
Message.define(:opt_set_ok,          :lobby, [],        "Option set")                       # S->C
Message.define(:opt_set_failed,      :lobby, [:reason], "Option not set")                   # S->C
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
Message.define(:command,       :game, [:text])
Message.define(:command_reply, :game, [:text])
Message.define(:act,           :game, [:command])
Message.define(:act_clarify,   :game, [:verb, :missing_params])
Message.define(:clarification, :game, [:missing_param])
Message.define(:act_fail,      :game, [:reason], "Failed to perform action")
Message.define(:act_success,   :game, [:description])
Message.define(:game_event,    :game, [:description])
Message.define(:user_dies,     :game, [:result], "User dies")

# Core Game Information
# Messages passed between the game lobby / game objects / lobby
Message.define(:tick,             :tick)
Message.define(:unit_moves,       :core, [:agent, :origin, :destination])
Message.define(:unit_moved,       :core, [:agent, :origin, :destination]) # Draw a distinction between whether or not a unit locomoted or was moved
Message.define(:unit_attacks,     :core, [:attacker, :defender, :success, :result_hash])
Message.define(:unit_acts,        :core, [:agent, :action, :location, :action_hash])
Message.define(:unit_renamed,     :core, [:agent, :name])
Message.define(:unit_speaks,      :core, [:agent, :statement, :response_needed])
Message.define(:unit_whispers,    :core, [:agent, :statement, :response_needed])

Message.define(:unit_animated,    :core, [:target, :location])
Message.define(:unit_killed,      :core, [:target, :location])

Message.define(:object_created,   :core, [:target, :location])
Message.define(:object_destroyed, :core, [:target, :location])

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
