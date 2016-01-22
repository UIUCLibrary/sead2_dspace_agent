require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    attr_accessor :aggregated_resources, :metadata, :status_url, :ore_url, :dspace_handle, :dspace_id

    def initialize(ore)

      @dspace_id     = nil
      @dspace_handle = nil

      @ore_url = ore['@id']
      @status_url = ore['@id'].gsub('oremap', 'status')

      key_elements = %w[dc.title dc.title.alternative dc.description dc.description.abstract dc.creator dc.subject dc.date dc.rights]

      @metadata             = {}
      @metadata[:id]        = ore["describes"]["@id"]    # Don't add this id in metadata
      @metadata[:title]     = ore["describes"]["Title"]
      @metadata[:alt_title] = ore["describes"]["Alternative Title"]
      @metadata[:abstract]  = ore["describes"]["Abstract"]
      @metadata[:rights]    = ore["Rights"]
      @metadata[:creator]   = ore["describes"]["Creator"]
      @metadata[:date]      = ore["describes"]["Creation Date"]
      # @metadata[:has_part]  = ore["describes"]["Has Part"]  # Only includes the agg resources' id
      @metadata[:subject]   = ore["describes"]["Keyword"]

      other_info                          = {}
      other_info["Funding Institution"]   = ore["describes"]["Funding Institution"]
      other_info["Time Period"]           = ore["describes"]["Time Periods"]
      other_info["Audience"]              = ore["describes"]["Audience"]
      other_info["Project Investigators"] = ore["describes"]["Principal Investigator(s)"]
      @metadata[:description]             = other_info.map{|k,v| "#{k} = #{v}"}.join('; ')



      ars                   = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map { |ar| AggregatedResource.new ar }
    end

  end


end