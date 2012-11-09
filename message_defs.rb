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
