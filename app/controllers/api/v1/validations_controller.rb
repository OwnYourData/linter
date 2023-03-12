module Api
    module V1
        class ValidationsController < ApiController
            def validate
                render json: {"valid": true},
                       status: 200
            end
        end
    end
end
