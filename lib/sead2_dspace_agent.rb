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

    dspace_connection.create_item(COLL_ID)
    dspace_connection.update_item_metadata(ro.metadata)

    ro.aggregated_resources.each do |ar|
      dspace_connection.update_item_bitstream(ar)
    end


  end


end
