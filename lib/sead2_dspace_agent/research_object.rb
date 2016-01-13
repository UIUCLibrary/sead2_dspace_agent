require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    attr_accessor :aggregated_resources, :metadata, :status_url, :dspace_handle, :dspace_id

    def initialize(ore)

      @dspace_id     = nil
      @dspace_handle = nil

      @ore_url = ore['id']
      @status_url = ore['@id'].gsub('oremap', 'status')

      @metadata            = {}
      @metadata[:id]       = ore["describes"]["@id"]
      @metadata[:title]    = ore["describes"]["Title"]
      @metadata[:abstract] = ore["describes"]["Abstract"]
      @metadata[:rights]   = ore["Rights"]
      @metadata[:creator]  = ore["describes"]["Creator"]
      @metadata[:date]     = ore["describes"]["Creation Date"]

      ars                   = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map { |ar| AggregatedResource.new ar }
    end

  end


end