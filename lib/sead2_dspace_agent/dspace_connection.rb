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

          content_type = response.content_type
          read_bytes   = 0
          chunk        = ''

          chunker = lambda do

            # special handling of chunked encoding
            if chunked? response.header['transfer-encoding']
              line = response.socket.readline
              hexlen = line.slice(/[0-9a-fA-F]+/) or
                  raise Net::HTTPBadResponse, "wrong chunk size line: #{line}"
              len = hexlen.hex
              return '' if len == 0
              begin
                chunk = response.socket.read(len)
              ensure
                read_bytes += len
                p "read #{read_bytes} of #{size} bytes expected"
                response.socket.read 2 # \r\n
              end
              return chunk.to_s
            end

            len = response.content_length
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
          ds_res = Excon.post(target_uri.to_s, :request_block => chunker, :headers => {'rest-dspace-token' => @login_token, content_type: content_type})

          return ds_res

        end
      end
    end

    def update_ore_bitstream(file)
      response = RestClient.post("#{@url}/rest/items/#{@itemid}/bitstreams?name=ore.json", file,
                                 {content_type: :json, accept: :json, rest_dspace_token: @login_token})

    end

    private

    # Returns "true" if the "transfer-encoding" header is present and
    # set to "chunked".  This is an HTTP/1.1 feature, allowing the
    # the content to be sent in "chunks" without at the outset
    # stating the entire content length.
    def chunked?(encoding)
      return false unless encoding
      (/(?:\A|[^\-\w])chunked(?![\-\w])/i =~ encoding) ? true : false
    end

  end

end
