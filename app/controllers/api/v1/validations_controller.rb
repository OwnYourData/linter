module Api
    module V1
        class ValidationsController < ApiController
            def validate
                soya = params[:soya].to_s
                if soya == ""
                    render json: {"valid": false, "error": "invalid/missing SOyA structure"},
                           status: 422
                    return
                end
                begin
                    if params.include?("_json")
                        input = JSON.parse(params.to_json)["_json"]
                        other = JSON.parse(params.to_json).except("_json", "validation", "format", "controller", "action", "application", "soya")
                        if other != {}
                            input += [other]
                        end
                    else
                        input = JSON.parse(params.to_json).except("validation", "format", "controller", "action", "application", "soya")
                    end
                rescue => ex
                    render json: {"valid": false, "error": "can't parse input"},
                           status: 422
                    return
                end

puts "SOyA: " + soya.to_s
puts "Document:"
puts input.to_json

                retVal = soya_validate(soya, input.to_json)
                render json: retVal,
                       status: 200
            end
        end
    end
end
