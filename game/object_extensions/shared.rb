class SharedObjectExtensions
    def self.check_required_params(params, required)
        required.each do |req|
            raise "Required parameter #{req} missing" unless params.has_key?(req)
        end
    end
end
