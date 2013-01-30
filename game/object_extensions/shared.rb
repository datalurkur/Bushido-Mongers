class SharedObjectExtensions
    def self.check_required_params(params, required)
        required.each do |req|
            raise(ArgumentError, "Required parameter #{req} missing.") unless params.has_key?(req)
        end
    end
end
