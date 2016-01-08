require 'rest-client'

module Sead2DspaceAgent

  class DspaceConnection

    def initialize(args = {})
      @url         = args['url']
      email        = args['email']
      password     = args['password']
      @login_token = RestClient.post("#{@url}/rest/login",
                                     {email: email, password: password}.to_json,
                                     {content_type: 'application/json', accept: 'application/json'})


    end

    def create_item(research_object)
      response = RestClient.post("#{@url}/rest/collections/116/items",
                                 {type: 'item'}.to_json,
                                 {content_type: 'application/json', accept: 'application/json', rest_dspace_token: @login_token})
    end

  end

end