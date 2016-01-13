require 'rest-client'

module Sead2DspaceAgent

  class SeadConnection

    def initialize(args = {})
      @c3pr_base_url = Sead2DspaceAgent::CONFIG['sead']['c3pr_base_url']
      @repository_id = Sead2DspaceAgent::CONFIG['sead']['repository_id']

      @use_proxy      = Sead2DspaceAgent::CONFIG['sead']['use_proxy']
      @proxy_base_url = Sead2DspaceAgent::CONFIG['sead']['proxy_base_url']
      @cookies        = @use_proxy ? Sead2DspaceAgent::CONFIG['sead']['proxy_cookies'] : {}

      @ro_list_url = "#{@c3pr_base_url}/repositories/#{@repository_id}/researchobjects"
      @ro_base_url = "#{@c3pr_base_url}/researchobjects"

    end

    def proxy_url(url)
      @use_proxy ? url.gsub(@c3pr_base_url, @proxy_base_url) : url
    end

    def get_new_researchojects
      response = RestClient.get(proxy_url(@ro_list_url), cookies: @cookies)
      ro_list  = JSON.parse response

      ro_list.select { |ro|
        ro['Status'].length == 1 and ro['Status'][0]['stage'] == 'Receipt Acknowledged'
      }.map { |ro|
        agg_id = CGI.escape(ro['Aggregation']['Identifier'])
        RestClient.get(proxy_url("#{@ro_base_url}/#{agg_id}"), cookies: @cookies)
      }.map { |ro|
        attrs    = JSON.parse ro
        ore_url  = attrs['Aggregation']['@id']
        response = RestClient.get(proxy_url(ore_url), cookies: @cookies)
        ore      = JSON.parse response
        ResearchObject.new ore
      }

    end

    def update_status(stage, message, research_object)
      RestClient.post(proxy_url("#{research_object.status_url}/status"),
                      {reporter: @repository_id, stage: stage, message: message}.to_json,
                      {cookies: @cookies, content_type: :json, accept: :json})
    end

  end

end