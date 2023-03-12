Rails.application.routes.draw do
    namespace :api, defaults: { format: :json } do
        scope "(:version)", :version => /v1/, module: :v1 do
            match 'validate/:dri', to: 'validations#validate', via: 'post'
        end
    end

    # Administrative ================
    match '/version',   to: 'application#version', via: 'get'
    match ':not_found', to: 'application#missing', via: [:get, :post], :constraints => { :not_found => /.*/ }
end
