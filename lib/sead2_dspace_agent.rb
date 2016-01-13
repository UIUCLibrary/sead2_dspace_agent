require 'sead2_dspace_agent/version'
require 'sead2_dspace_agent/config'
require 'sead2_dspace_agent/research_object'
require 'sead2_dspace_agent/aggregated_resource'
require 'sead2_dspace_agent/dspace_connection'
require 'sead2_dspace_agent/sead_connection'

module Sead2DspaceAgent

  sead_connection = SeadConnection.new
  researchobjects = sead_connection.get_new_researchojects

  dspace_connection = DspaceConnection.new

  researchobjects.each do |ro|

    sead_connection.update_status('Pending', 'Processing research object', ro)

    begin
      ro.dspace_id, ro.dspace_handle = dspace_connection.create_item(116)
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

    sead_connection.update_status('Success', ro.dspace_handle, ro)

  end
end
