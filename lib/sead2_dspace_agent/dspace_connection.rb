require 'rest-client'
require 'net/http'
require 'excon'

class Net::HTTPResponse
  attr_reader :socket
end

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

      response = RestClient.put("#{@url}/rest/items/#{@itemid}/metadata", ro_metadata.to_json,
                                {content_type: :json, accept: :json, rest_dspace_token: @login_token})
    end

    def update_item_bitstream(filename, url, size, cookies = {})

      uri = URI(url)
      content_type = "text/plain"
      target_uri = URI("#{@url}/rest/items/#{@itemid}/bitstreams?name=#{CGI.escape(filename)}")

      begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new uri

          http.request request do |response|
            len = response.content_length || size
            p "reading #{len} bytes..."
            read_bytes = 0
            chunk      = ''

            chunker = lambda do
              begin
                if read_bytes + Excon::CHUNK_SIZE < len
                  chunk      = response.socket.read(Excon::CHUNK_SIZE)
                  read_bytes += chunk.size
                else
                  chunk      = response.socket.read(len - read_bytes)
                  read_bytes += chunk.size
                end
              rescue EOFError
                # ignore eof
              end
              p "read #{read_bytes} bytes"
              chunk
            end

            Excon.ssl_verify_peer = false
            Excon.post(target_uri.to_s, :request_block => chunker, :headers => {'rest-dspace-token' => @login_token, content_type: content_type})

            p 'Done!'

          end
        end
      end
    end

  end

end
