class ApplicationController < ActionController::API
    def version
        render json: {"service": "general linting", "version": VERSION.to_s}.to_json,
               status: 200
    end

    def missing
        render json: {"error": "invalid path"},
               status: 404
    end	
end
