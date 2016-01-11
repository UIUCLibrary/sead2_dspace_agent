require 'rest-client'
require_relative 'research_object'

module Sead2DspaceAgent

  class SeadConnection

    def initialize(args = {})
      c3pr_base_url         = args['c3pr_base_url']
      repository_id = args['repository_id']
      @ro_list_url = "#{c3pr_base_url}/repositories/#{repository_id}/researchobjects"
      @ro_base_url = "#{c3pr_base_url}/researchobjects"
    end

    def get_new_researchojects
      response = RestClient.get(@ro_list_url, cookies: {'JSESSIONID' => 'C619F064CE7ED01B58131030304D9566'})
      ro_list = JSON.parse response

      ro_list.select{ |ro|
        ro['Status'].length == 1 and ro['Status'][0]['stage'] == 'Receipt Acknowledged'
      }.map { |ro|
        agg_id = CGI.escape(ro['Aggregation']['Identifier'])
        ro_url = "#{@ro_base_url}/#{agg_id}"
        RestClient.get(ro_url, cookies: {'JSESSIONID' => 'C619F064CE7ED01B58131030304D9566'})
      }.map { |ro|
        attrs = JSON.parse ro
        ore_url = attrs['Aggregation']['@id']
        ore_url = "https://sead-test.ncsa.illinois.edu/c3pr/proxy/sead-c3pr/api/researchobjects/urn%3Auuid%3A56901ddee4b073da5f137e8c/oremap#aggregation"
        ResearchObject.new ore_url
      }

    end

  end

end