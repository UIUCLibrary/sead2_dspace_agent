require 'sead2_dspace_agent/version'
require 'sead2_dspace_agent/research_object'
require 'sead2_dspace_agent/dspace_connection'
require 'sead2_dspace_agent/sead_connection'

require 'yaml'

module Sead2DspaceAgent

  COLL_ID = 116;

  @config = YAML::load_file('../config/config.yml')

  sead_connection = SeadConnection.new(@config['sead'])
  researchobjects = sead_connection.get_new_researchojects

  dspace_connection = DspaceConnection.new(@config['dspace'])

  researchobjects.each do |ro|

    sead_connection.update_status('Pending', 'Processing research object', ro)

    begin
      ro.dspace_id, ro.dspace_handle = dspace_connection.create_item(COLL_ID)
    rescue => e
      sead_connection.update_status('Failure', "Error creating DSpace item: #{e.message}", ro)
    end

    begin
      dspace_connection.update_item_metadata(ro.metadata)
    rescue => e
      sead_connection.update_status('Failure', "Error updating DSpace item metadata: #{e.message}", ro)
    end

    ro.aggregated_resources.each do |ar|

      begin
        dspace_connection.update_item_bitstream(ar)
      rescue => e
        sead_connection.update_status('Failure', "Error submitting #{ar.title}: #{e.message}", ro)
      end

    end

    sead_connection.update_status('Success', 'Processing research object', ro)

  end


end
