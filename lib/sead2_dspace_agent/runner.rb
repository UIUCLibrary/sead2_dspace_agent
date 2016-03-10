require 'logger'

module Sead2DspaceAgent
  class Runner

    def initialize(options = {})

      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}: #{msg}\n"
      end


    end

    def run

      # Establish SEAD connection
      sead_connection = SeadConnection.new
      @logger.info 'SEAD connection established'

      # Get new research objects
      researchobjects = sead_connection.get_new_researchojects
      @logger.info "Received #{researchobjects.length} research objects for processing"

      # Establish DSpace connection
      dspace_connection = DspaceConnection.new
      @logger.info 'DSpace connection established'

      # Process research objects
      @logger.info "Processing #{researchobjects.length} new research objects"
      researchobjects.each do |ro|
        @logger.info "Processing research object: #{ro.metadata[:id]}"

        # Set status to pending
        sead_connection.update_status('Pending', 'Processing research object', ro)
        @logger.info 'Status set to Pending'

        # Create the DSpace item
        begin
          ro.dspace_id, ro.dspace_handle = dspace_connection.create_item(1)
          @logger.info "DSpace item #{ro.dspace_id} created at #{ro.dspace_handle}"
        rescue => e
          sead_connection.update_status('Failure', "Error creating DSpace item: #{e.message}", ro)
          @logger.error "Failed to create DSpace item #{ro.dspace_id} created at #{ro.dspace_handle}: #{e.message}"
          dspace_connection.delete_item
          next # give up and go to the next ro
        end

        # Update DSpace metadata
        begin
          dspace_connection.update_item_metadata(ro.all_metadata)
          @logger.info "Metadata updated for DSpace item #{ro.dspace_id} created at #{ro.dspace_handle}"
        rescue => e
          sead_connection.update_status('Failure', "Error updating DSpace item metadata: #{e.message}", ro)
          @logger.error "Failed to update metadata for DSpace item #{ro.dspace_id} at #{ro.dspace_handle}: #{e.message}"
          dspace_connection.delete_item
          next # give up and go to the next ro
        end

        # Process ARs
        @logger.info "Processing #{ro.aggregated_resources.length} aggregated resources for research object: #{ro.metadata[:id]}"
        errors = false
        ro.aggregated_resources.each do |ar|
          @logger.info "Processing aggregated resource: #{ar.title}"

          # Deposit AR into DSpace
          begin
            @logger.info "Uplading #{ar.title} to DSpace item #{ro.dspace_id} at #{ro.dspace_handle}"
            dspace_connection.update_item_bitstream(ar.title, ar.file_url, ar.size)
            @logger.info "Success"
          rescue => e
            sead_connection.update_status('Failure', "Error submitting #{ar.title}: #{e.message}", ro)
            @logger.error "Failed to upload #{ar.title} to DSpace item #{ro.dspace_id} at #{ro.dspace_handle}: #{e.message}"
            errors = true
            next # give up and go to the next ro
          end

        end
        if errors
          @logger.error "Failed to upload one or more ARs to DSpace item #{ro.dspace_id} at #{ro.dspace_handle}. Giving up."
          dspace_connection.delete_item
          next
        end

        # Deposit ORE ReM as a DSpace bitstream
        begin
          dspace_connection.update_item_bitstream('ore.json', sead_connection.proxy_url(ro.ore_url), sead_connection.cookies)
          @logger.info "Uploaded ore.json to DSpace item #{ro.dspace_id} at #{ro.dspace_handle}"
        rescue => e
          sead_connection.update_status('Failure', "Error submitting ore.json: #{e.message}", ro)
          @logger.error "Failed to upload ore.json to DSpace item #{ro.dspace_id} at #{ro.dspace_handle}: #{e.message}"
          dspace_connection.delete_item
          next # give up and go to the next ro
        end

        # Update status
        sead_connection.update_status('Success', ro.dspace_handle, ro)
        @logger.info "Successfully created DSpace item #{ro.dspace_id} at #{ro.dspace_handle}"

      end
      @logger.info "Done processing #{researchobjects.length} research objects"
    end
  end
end