require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    attr_accessor :aggregated_resources, :metadata, :status_url, :ore_url, :dspace_handle, :dspace_id, :sub, :collect_sub, :all_metadata

    def initialize(ore)

      @dspace_id     = nil
      @dspace_handle = nil

      @ore_url = ore['@id']
      @status_url = ore['@id'].gsub('oremap', 'status')

      def skip_fields(id)
        if @metadata[id] =! nil
          @metadata[id]*", "
        else
          continue
        end

      end
      @metadata             = {}
      @metadata[:id]        = ore["describes"]["@id"]    # Don't add this id in metadata
      @metadata[:title]     = ore["describes"]["Title"]
      @metadata[:rights]    = ore["Rights"]
      @metadata[:date]      = ore["describes"]["Creation Date"]


      @metadata[:alt_title] = skip_fields("Alternative Title")*", "
      @metadata[:abstract]  = skip_fields("Abstract")*", "
      @metadata[:temporal]  = skip_fields("Start/End Date")*", "
      @metadata[:references]= skip_fields("References")*", "

      # Get all the fields that cannot be directly mapped to DC terms
      other_info                          = {}
      other_info["Uploaded By"]           = ore["describes"]["Uploaded By"]
      other_info["Funding Institution"]   = ore["describes"]["Funding Institution"]*", "
      # other_info["Grant Number"]          = ore["describes"]["Grant Number"]*", "
      # other_info["Publisher"]             = ore["describes"]["Publisher"]*", "
      other_info["Time Period"]           = ore["describes"]["Time Periods"]*", "
      other_info["Project Investigators"] = ore["describes"]["Principal Investigator(s)"]*", "
      # other_info["Contact"]               = ore["describes"]["Contact"]*", "
      other_info["Audience"]              = ore["describes"]["Audience"]*", "
      # other_info["Bibliographic Citation"]= ore["describes"]["Bibliographic Citation"]*", "
      # other_info["Related Publications"]  = ore["describes"]["Related Publications"]*", "
      @metadata[:description] = other_info.map{|k,v| "#{k}: #{v}"}.join('; ')

      # Create separate hash for each subjects and creators
      def mult_values(keys, arrays)
        if arrays != nil
          arrays.each do |i|
            @collect_sub << {'key' => keys, 'value' => i, 'language' => 'eng'}
          end
        end
      end

      @sub = ore["describes"]["Keywords"]
      @creator = ore["describes"]["Creator"]
      @collect_sub = Array.new
      mult_values('dc.subject', @sub)
      mult_values('dc.creator', @creator)


      @all_metadata = Array.new
      @all_metadata.concat(@collect_sub)
      keys = %w[dc.title dc.title.alternative dc.description dc.description.abstract dc.date dc.rights dc.coverage.temporal dc.relation.references]
      values = [@metadata[:title], @metadata[:alt_title], @metadata[:description], @metadata[:abstract], @metadata[:date], @metadata[:rights], @metadata[:temporal], @metadata[:references]]

      keys.zip(values).each do|i, j|
        @all_metadata << {'key'=> i , 'value'=> j , 'language' => 'eng'}
      end


      ars                   = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map { |ar| AggregatedResource.new ar }
    end

  end


end