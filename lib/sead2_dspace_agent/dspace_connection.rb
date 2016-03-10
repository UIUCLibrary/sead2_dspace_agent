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

      item = JSON.parse(response)

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

    def update_item_bitstream(filename, url, size)

      uri        = URI(url)
      target_uri = URI("#{@url}/rest/items/#{@itemid}/bitstreams?name=#{CGI.escape(filename)}")


      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          len          = response.content_length || size
          content_type = response.content_type
          read_bytes   = 0
          chunk        = ''

          chunker = lambda do
            begin
              if read_bytes + Excon::CHUNK_SIZE < len
                chunk      = response.socket.read(Excon::CHUNK_SIZE)
                read_bytes += chunk.size
              else
                chunk      = response.socket.read(len - read_bytes)
                read_bytes += chunk.size
              end
            rescue EOFError, TypeError
              # ignore eof
            end
            chunk
          end

          Excon.ssl_verify_peer = false
          Excon.post(target_uri.to_s, :request_block => chunker, :headers => {'rest-dspace-token' => @login_token, content_type: content_type})

          # not sure about this -- need to return to break out of the
          # block when the content length is unknown.
          return unless response.content_length

        end
      end
    end

    def update_ore_bitstream(file)
      response = RestClient.post("#{@url}/rest/items/#{@itemid}/bitstreams?name=ore.json", file,
                                 {content_type: :json, accept: :json, rest_dspace_token: @login_token})

    end

  end

end
