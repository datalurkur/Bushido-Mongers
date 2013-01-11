require './util/basic'

class String
    def xor(other)
        l = [self.length, other.length].max
        (0...l).collect do |i|
            (self[i] || 0x00).ord ^ (other[i] || 0x00).ord
        end.pack("C*")
    end
end

# Seriously, guys, this isn't real crypto.  Don't use this for anything that *actually* needs to be secure
module LameCrypto
    def self.hash_using_method(method, password, server_hash)
        case method
        when :md5_and_xor
            LameCrypto.md5_and_xor(password, server_hash)
        else
            raise "Unrecognized hashing method #{method} requested by server"
        end
    end

    def self.md5_and_xor(password, server_md5)
        (password || "").md5.xor(server_md5 || "")
    end
end
