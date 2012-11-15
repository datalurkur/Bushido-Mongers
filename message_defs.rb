# Client / Server Messages
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
Message.define(:send_chat,          :lobby, [:chat_text])
Message.define(:send_whisper,       :lobby, [:recipient,:chat_text])
Message.define(:receive_chat,       :lobby, [:sender,:chat_text,:is_whisper])

# Game / World generation
Message.define(:get_game_params,    :lobby)                # C->S
Message.define(:game_params,        :lobby, [:params])     # S->C
Message.define(:generate_game,      :lobby)                # C->S
Message.define(:generation_success, :lobby)                # S->C
Message.define(:generation_fail,    :lobby, [:reason])     # S->C

# Character creation / selection
# FIXME - This needs some looking at (specifically, we need some kind of feedback that the character template was valid, or the choice was valid, along with the necessary state to determine if we should now proceed to playing or waiting for the game to start
Message.define(:create_character,   :lobby, [:attributes]) # C->S
Message.define(:list_characters,    :lobby)                # C->S
Message.define(:character_list,     :lobby, [:characters]) # S->C
Message.define(:select_character,   :lobby)                # C->S

# Game administration and information
Message.define(:start_game,         :lobby)                # C->S
Message.define(:start_success,      :lobby)                # S->C
Message.define(:start_fail,         :lobby, [:reason])     # S->C
Message.define(:toggle_pause,       :lobby)                # C->S
Message.define(:pause_state,        :lobby)                # S->C

Message.define(:user_joins,         :lobby, [:username])   # S->C
Message.define(:user_leaves,        :lobby, [:username])   # S->C
Message.define(:admin_change,       :lobby, [:admin])      # S->C

# Client / Interface Messages
# Interface Messages
# This group is a special class of messages which are used by the state to perform interactions
# Each prompt must have a "field" attribute
Message.define(:text_field,       :prompt,   [:field])
Message.define(:choose_from_list, :prompt,   [:field,:choices])
Message.define(:valid_input,      :response, [:input])
Message.define(:invalid_input,    :response)

# Mostly just raw text messages
Message.define(:notify,         :interface, [:text])
Message.define(:list,           :interface, [:title,:items])
Message.define(:raw_command,    :interface, [:command])
