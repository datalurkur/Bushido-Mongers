# Client / Server Messages
# Login phase
Message.define(:login_request, :protocol, [:username])
Message.define(:login_reject,  :protocol, [:reason])
Message.define(:auth_request,  :protocol, [:hash_method,:server_hash])
Message.define(:auth_response, :protocol, [:password_hash])
Message.define(:auth_reject,   :protocol, [:reason])
Message.define(:auth_accept,   :protocol, [])

# Interface Messages
Message.define(:query,       :interface, [:field])
Message.define(:response,    :interface, [:value])
Message.define(:choose,      :interface, [:field, :choices])
Message.define(:choice,      :interface, [:choice])
Message.define(:notify,      :interface, [:text])
Message.define(:raw_command, :interface, [:command])
