require_relative 'aggregated_resource'

module Sead2DspaceAgent

  class ResearchObject

    attr_accessor :aggregated_resources, :metadata, :status_url, :ore_url, :dspace_handle, :dspace_id, :all_metadata, :creator, :abstract

    def initialize(ore)

      @dspace_id     = nil
      @dspace_handle = nil

      @ore_url = ore['@id']
      @status_url = ore['@id'].gsub('oremap', 'status')

      @metadata             = {}
      @metadata[:id]        = ore["describes"]["@id"]    # Don't add this id in metadata


      # join values of non-dc terms to post as single value for description
      def join_values(k, a)
        if a.nil?
          return
        elsif a.kind_of?(Array) && !a.nil?
          @other_info[k] = a*", "
        elsif a.kind_of?(String) && !a.nil?
          @other_info[k] = a
        end
      end

      # Create separate hash for each dc terms
      def mult_values(keys, values)
        if values.nil?
          return
        elsif values.is_a? Array
          values.each do |i|
            @all_metadata << {'key' => keys, 'value' => i, 'language' => 'eng'}
          end
        elsif values.is_a? String
          @all_metadata << {'key' => keys, 'value' => values, 'language' => 'eng'}
        else
          return
        end
      end


      # Get all the fields that cannot be directly mapped to DC terms
      @all_metadata    = Array.new
      @other_info = {}
      begin
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
        description = @other_info.map{|k,v| "#{k}: #{v}"}.join('; ')
      rescue => e
        "#{e.message}"
      end

      @all_metadata << {'key' => 'dc.description', 'value' => description, 'language' => 'eng'}

      @sub        = ore["describes"]["Keywords"]
      @creator    = ore["describes"]["Creator"]
      @alt_title  = ore["describes"]["Alternative Title"]
      @abstract   = ore["describes"]["Abstract"]
      @time       = ore["describes"]["Start/End Date"]
      @references = ore["describes"]["References"]
      @title      = ore["describes"]["Title"]
      @rights     = ore["Rights"]
      @date       = ore["describes"]["Creation Date"]

      begin
        mult_values('dc.subject', @sub)
        mult_values('dc.creator', @creator)
        mult_values('dc.title.alternative', @alt_title)
        mult_values('dc.description.abstract', @abstract)
        mult_values('dc.coverage.temporal', @time)
        mult_values('dc.relation.references', @references)
        mult_values('dc.title', @title)
        mult_values('dc.rights', @rights)
        mult_values('dc.date', @date)
      rescue => e
        "#{e.message}"
      end

      # Metadata for aggregated resources
      ars                   = ore["describes"]["aggregates"]
      @aggregated_resources = ars.map { |ar| AggregatedResource.new ar }
    end

  end


end