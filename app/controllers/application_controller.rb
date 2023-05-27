class ApplicationController < ActionController::API
    include ActionController::RequestForgeryProtection
    def version
        render json: {"service": "general linter", "version": VERSION.to_s}.to_json,
               status: 200
    end

    def missing
        render json: {"error": "invalid path"},
               status: 404
    end

    def soya_validate(soya, json_input)
        # Command line
        cmd = "echo '#{json_input}' | soya acquire #{soya} | soya validate #{soya}"
        out = nil

        require 'open3'
        Open3.popen3(cmd) {|stdin, stdout, stderr, wait_thr|
          pid = wait_thr.pid # pid of the started process.
          out = stdout.gets(nil)
          exit_status = wait_thr.value # Process::Status object returned.
        }
        return parse_soya_output(out)

    end

    def parse_soya_output(soya_stdout)

        # check for plain error message
        if soya_stdout[0,16] == "\e[31merror\e[39m:"
            return {"valid": false, "errors": [{"value":"soya-cli", "error": soya_stdout[soya_stdout.rindex("error:")+7, soya_stdout.length].strip}]}
            exit
        end

        # try to parse response
        result = JSON.parse(soya_stdout) rescue nil
        if result.nil?
            return {"valid": false, "errors": [{"value":"soya-cli", "error": "cannot validate input"}]}
        end
        if result["isValid"]
            return {"valid": true}
        end
        retVal = {"valid": false}
        result["results"].each do |r|
            msg = r["message"] rescue nil
            if msg == [] || msg.to_s == ""
                val = r["value"] rescue nil
                if val.nil?
                    val = r["severity"]["value"].to_s rescue nil
                end
                if val.to_s != ""
                    case val
                    when "http://www.w3.org/ns/shacl#Violation"
                        obj = {"value": "Verification Relationship", "error": "missing"}
                    else    
                        obj = {"value": r["value"], "error": "invalid"}
                    end
                    if retVal["errors"].nil?
                        retVal["errors"] = [obj]
                    else
                        retVal["errors"] << obj
                        retVal["errors"] = retVal["errors"].flatten
                    end
                end
            else
                obj = {"value": r["value"], "error": r["message"].first["value"]} rescue nil
                if !obj.nil?
                    if retVal["errors"].nil?
                        retVal["errors"] = [obj]
                    else
                        retVal["errors"] << obj
                        retVal["errors"] = retVal["errors"].flatten
                    end
                end
            end
        end
        return retVal
    end

end
