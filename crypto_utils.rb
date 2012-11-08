# Seriously, guys, this isn't real crypto.  Don't use this for anything that *actually* needs to be secure

class String
    def xor(other)
        l = [self.length, other.length].max
        (0...l).collect do |i|
            (self[i] || 0x00) ^ (other[i] || 0x00)
        end.pack("C*")
    end
end

module LameCrypto
    def self.md5_and_xor(password, server_md5)
        Digest::MD5.digest(password).xor(server_md5)
    end
end
