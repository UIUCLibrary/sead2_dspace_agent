require 'rest-client'
require 'net/http'

module Sead2DspaceAgent

  class DspaceConnection

    def initialize(args = {})
      @url         = Sead2DspaceAgent::CONFIG['dspace']['url']
      email        = Sead2DspaceAgent::CONFIG['dspace']['email']
      password     = Sead2DspaceAgent::CONFIG['dspace']['password']
      @login_token = RestClient.post("#{@url}/rest/login",
                                     {email: email, password: password}.to_json,
                                     {content_type: :json, accept: :json})

      @itemid, @handle = nil
    end

    def create_item(collection_id)
      response = RestClient.post("#{@url}/rest/collections/#{collection_id}/items",
                                 {type: 'item'}.to_json,
                                 {content_type: :json, accept: :json, rest_dspace_token: @login_token})

      item             = JSON.parse(response)

      @itemid = item['id']
      @handle = "http://hdl.handle.net/#{item['handle']}"
      
      return @itemid, @handle
    end


    def delete_item
      response = RestClient.delete("#{@url}/rest/items/#{@itemid}",
                                   {content_type: :json, accept: :json, rest_dspace_token: @login_token})

    end

    def update_item_metadata(ro_metadata)
      metadata = [{key: 'dc.identifier', value: ro_metadata[:id], language: 'en'},
                  {key: 'dc.date', value: ro_metadata[:date], language: 'en'},
                  {key: 'dc.title', value: ro_metadata[:title], language: 'en'},
                  {key: 'dc.description.abstract', value: ro_metadata[:abstract], language: 'en'},
                  {key: 'dc.creator', value: ro_metadata[:creator][0].split(':')[0], language: 'en'},
                  {key: 'dc.rights', value: ro_metadata[:rights], language: 'en'}]

      response = RestClient.put("#{@url}/rest/items/#{@itemid}/metadata", metadata.to_json,
                                {content_type: :json, accept: :json, rest_dspace_token: @login_token})
    end

    def update_item_bitstream(filename, url, cookies = {})
      bitstream = Tempfile.new(filename)
      name      = CGI.escape filename

      uri = URI(url)
      content_type = "text/plain"

      begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new uri
          cookies.each { |k, v|
            request['Cookie'] = CGI::Cookie.new(k, v).to_s
          }

          http.request request do |response|
            content_type = response['content-type']
            open bitstream, 'w' do |io|
              response.read_body do |chunk|
                io.write chunk
              end
            end
          end
        end

        response = RestClient.post("#{@url}/rest/items/#{@itemid}/bitstreams?name=#{name}", bitstream,
                                   {content_type: content_type, accept: :json, rest_dspace_token: @login_token})
      ensure
        bitstream.close
        bitstream.unlink # deletes the temp file
      end

    end

  end

end
