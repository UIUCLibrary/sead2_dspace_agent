require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    attr_accessor :aggregated_resources, :metadata

    def initialize(url)

      response = RestClient.get(url, cookies: {'JSESSIONID' => 'C619F064CE7ED01B58131030304D9566'})
      ore = JSON.parse response

      @metadata = {}
      @metadata[:id] = ore["describes"]["@id"]
      @metadata[:title] = ore["describes"]["Title"]
      @metadata[:abstract] = ore["describes"]["Abstract"]
      @metadata[:rights] = ore["Rights"]
      @metadata[:creator] = ore["describes"]["Creator"]
      @metadata[:date] = ore["describes"]["Creation Date"]

      ars = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map{ |ar| AggregatedResource.new ar }
    end

  end


end