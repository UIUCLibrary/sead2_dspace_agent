require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    def initialize(url)

      response = RestClient.get(url, cookies: {'JSESSIONID' => 'D0F6EEE797C04CE9C968EF9E4FEC3CA2'})
      ore = JSON.parse response

      @id = ore["describes"]["@id"]
      @title = ore["describes"]["Title"]
      @abstract = ore["describes"]["Abstract"]
      @rights = ore["Rights"]
      @creator = ore["describes"]["Creator"]
      @date = ore["describes"]["Creation Date"]

      ars = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map{ |ar| AggregatedResource.new ar }
    end

  end


end