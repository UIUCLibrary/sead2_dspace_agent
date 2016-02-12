require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    attr_accessor :aggregated_resources, :metadata, :status_url, :ore_url, :dspace_handle, :dspace_id, :all_metadata

    def initialize(ore)

      @dspace_id     = nil
      @dspace_handle = nil

      @ore_url = ore['@id']
      @status_url = ore['@id'].gsub('oremap', 'status')

      @metadata             = {}
      @metadata[:id]        = ore["describes"]["@id"]    # Don't add this id in metadata
      @metadata[:title]     = ore["describes"]["Title"]
      @metadata[:alt_title] = ore["describes"]["Alternative Title"]*", "
      @metadata[:abstract]  = ore["describes"]["Abstract"]*", "
      @metadata[:rights]    = ore["Rights"]
      @metadata[:creator]   = ore["describes"]["Uploaded By"]
      @metadata[:date]      = ore["describes"]["Creation Date"]
      # @metadata[:has_part]  = ore["describes"]["Has Part"]  # Only includes the agg resources' id
      @metadata[:subject]   = ore["describes"]["Keywords"]*", "

      other_info                          = {}
      other_info["Funding Institution"]   = ore["describes"]["Funding Institution"]*", "
      other_info["Time Period"]           = ore["describes"]["Time Periods"]*", "
      other_info["Audience"]              = ore["describes"]["Audience"]*", "
      other_info["Project Investigators"] = ore["describes"]["Principal Investigator(s)"]*", "
      @metadata[:description] = other_info.map{|k,v| "#{k} = #{v}"}.join('; ')

      @all_metadata = Array.new
      keys = %w[dc.title dc.title.alternative dc.description dc.description.abstract dc.creator dc.subject dc.date dc.rights]
      values = [@metadata[:title], @metadata[:alt_title], @metadata[:description], @metadata[:abstract], @metadata[:creator], @metadata[:subject], @metadata[:date], @metadata[:rights]]

      keys.zip(values).each do|i, j|
        @all_metadata << {'key'=> i , 'value'=> j , 'language' => 'eng'}
      end



      ars                   = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map { |ar| AggregatedResource.new ar }
    end

  end


end