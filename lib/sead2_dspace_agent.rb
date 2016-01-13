require 'sead2_dspace_agent/version'
require 'sead2_dspace_agent/config'
require 'sead2_dspace_agent/research_object'
require 'sead2_dspace_agent/aggregated_resource'
require 'sead2_dspace_agent/dspace_connection'
require 'sead2_dspace_agent/sead_connection'

require 'logger'

module Sead2DspaceAgent

  logger = Logger.new(STDOUT)
  logger.level = Logger::INFO
  logger.formatter = proc do |severity, datetime, progname, msg|
    "#{severity}: #{msg}\n"
  end

  sead_connection = SeadConnection.new
  logger.info 'SEAD connection established'

  researchobjects = sead_connection.get_new_researchojects
  logger.info "Recieved #{researchobjects.length} research objects for processing"

  dspace_connection = DspaceConnection.new
  logger.info 'DSpace connection established'

  logger.info "Processing #{researchobjects.length} new research objects"
  researchobjects.each do |ro|
    logger.info "Processing research object: #{ro.metadata[:id]}"

    sead_connection.update_status('Pending', 'Processing research object', ro)
    logger.info 'Status set to Pending'

    begin
      ro.dspace_id, ro.dspace_handle = dspace_connection.create_item(116)
      logger.info "DSpace item #{ro.dspace_id} created at #{ro.dspace_handle}"
    rescue => e
      sead_connection.update_status('Failure', "Error creating DSpace item: #{e.message}", ro)
      logger.error "Failed to create DSpace item #{ro.dspace_id} created at #{ro.dspace_handle}: #{e.message}"
      next # give up and go to the next ro
    end

    begin
      dspace_connection.update_item_metadata(ro.metadata)
      logger.info "Metadata updated for DSpace item #{ro.dspace_id} created at #{ro.dspace_handle}"
    rescue => e
      sead_connection.update_status('Failure', "Error updating DSpace item metadata: #{e.message}", ro)
      logger.error "Failed to update metadata for DSpace item #{ro.dspace_id} at #{ro.dspace_handle}: #{e.message}"
      next # give up and go to the next ro
    end

    logger.info "Processing #{ro.aggregated_resources.length} aggregated resources for research object: #{ro.metadata[:id]}"
    ro.aggregated_resources.each do |ar|
      logger.info "Processing aggregated resource: #{ar.title}"

      begin
        dspace_connection.update_item_bitstream(ar)
        logger.info "Uploaded #{ar.title} to DSpace item #{ro.dspace_id} at #{ro.dspace_handle}"
      rescue => e
        sead_connection.update_status('Failure', "Error submitting #{ar.title}: #{e.message}", ro)
        logger.error "Failed to upload #{ar.title} to DSpace item #{ro.dspace_id} at #{ro.dspace_handle}: #{e.message}"
      end

    end

    sead_connection.update_status('Success', ro.dspace_handle, ro)
    logger.info "Successfully created DSpace item #{ro.dspace_id} at #{ro.dspace_handle}"

  end
  logger.info "Done processing #{researchobjects.length} research objects"
end
