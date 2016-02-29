require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    attr_accessor :aggregated_resources, :metadata, :status_url, :ore_url, :dspace_handle, :dspace_id, :sub, :collect_sub, :all_metadata

    def initialize(ore)

      @dspace_id     = nil
      @dspace_handle = nil

      @ore_url = ore['@id']
      @status_url = ore['@id'].gsub('oremap', 'status')

      @metadata             = {}
      @metadata[:id]        = ore["describes"]["@id"]    # Don't add this id in metadata
      @metadata[:title]     = ore["describes"]["Title"]
      @metadata[:rights]    = ore["Rights"]
      @metadata[:date]      = ore["describes"]["Creation Date"]


      def join_values(k, a)
        if a.nil?
          return
        elsif a.kind_of?(Array) && !a.nil?
          @other_info[k] = a*", "
        elsif a.kind_of?(String) && !a.nil?
          @other_info[k] = a
        end
      end

      # Create separate hash for each subjects and creators
      def mult_values(keys, arrays)
        unless arrays.nil?
          arrays.each do |i|
            @collect << {'key' => keys, 'value' => i, 'language' => 'eng'}
          end
        end
      end

      # Get all the fields that cannot be directly mapped to DC terms
      @other_info = {}
      join_values('Uploaded By', ore["describes"]["Uploaded By"])
      join_values('Funding Institution', ore["describes"]["Funding Institution"])
      join_values('Grant Number', ore["describes"]["Grant Number"])
      join_values('Publisher', ore["describes"]["Publisher"])
      join_values('Time Period', ore["describes"]["Time Periods"])
      join_values('Project Investigators', ore["describes"]["Principal Investigator(s)"])
      join_values('Contact', ore["describes"]["Contact"])
      join_values('Audience', ore["describes"]["Audience"])
      join_values('Bibliographic Citation', ore["describes"]["Bibliographic Citation"])
      join_values('Related Publications', ore["describes"]["Related Publications"])
      @metadata[:description] = @other_info.map{|k,v| "#{k}: #{v}"}.join('; ')


      @collect    = Array.new
      @sub        = ore["describes"]["Keywords"]
      @creator    = ore["describes"]["Creator"]
      @alt_title  = ore["describes"]["Alternative Title"]
      @abstract   = ore["describes"]["Abstract"]
      @time       = ore["describes"]["Start/End Date"]
      @references = ore["describes"]["References"]

      mult_values('dc.subject', @sub)
      mult_values('dc.creator', @creator)
      mult_values('dc.title.alternative', @alt_title)
      mult_values('dc.description.abstract', @abstract)
      mult_values('dc.coverage.temporal', @time)
      mult_values('dc.relation.references', @references)


      @all_metadata = Array.new
      @all_metadata.concat(@collect)
      keys = %w[dc.title dc.description dc.date dc.rights]
      values = [@metadata[:title], @metadata[:description], @metadata[:date], @metadata[:rights]]

      keys.zip(values).each do|i, j|
        @all_metadata << {'key'=> i , 'value'=> j , 'language' => 'eng'}
      end


      ars                   = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map { |ar| AggregatedResource.new ar }
    end

  end


end