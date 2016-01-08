require 'sead2_dspace_agent/version'
require 'sead2_dspace_agent/research_object'
require 'sead2_dspace_agent/dspace_connection'
require 'sead2_dspace_agent/sead_connection'

require 'yaml'

module Sead2DspaceAgent

  @config = YAML::load_file('../config/config.yml')

  sead_connection = SeadConnection.new(@config['sead'])
  researchobjects = sead_connection.get_new_researchojects

  researchobjects.each do |ro|
    p ro
  end

  dspace_connection = DspaceConnection.new(@config['dspace'])

end
