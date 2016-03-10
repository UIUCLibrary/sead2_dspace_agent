require 'rest-client'

module Sead2DspaceAgent

  class SeadConnection

    def initialize(args = {})
      @c3pr_base_url = Sead2DspaceAgent::CONFIG['sead']['c3pr_base_url']
      @repository_id = Sead2DspaceAgent::CONFIG['sead']['repository_id']

      @ro_list_url = "#{@c3pr_base_url}/repositories/#{@repository_id}/researchobjects"
      @ro_base_url = "#{@c3pr_base_url}/researchobjects"

    end

    def get_new_researchojects
      response = RestClient.get(@ro_list_url)
      ro_list  = JSON.parse response

      ro_list.select { |ro|
        ro['Status'].length == 1 and ro['Status'][0]['stage'] == 'Receipt Acknowledged'
      }.map { |ro|
        agg_id = CGI.escape(ro['Aggregation']['Identifier'])
        RestClient.get("#{@ro_base_url}/#{agg_id}")
      }.map { |ro|
        attrs    = JSON.parse ro
        ore_url  = attrs['Aggregation']['@id']
        response = RestClient.get(ore_url)
        ore      = JSON.parse response
        ResearchObject.new ore
      }

    end

    def update_status(stage, message, research_object)
      RestClient.post(research_object.status_url,
                      {reporter: @repository_id, stage: stage, message: message}.to_json,
                      {content_type: :json, accept: :json}) if Sead2DspaceAgent::CONFIG['env'] == 'production'
    end

  end

end