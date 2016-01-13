require 'yaml'

module Sead2DspaceAgent
  CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../../config/config.yml")
end