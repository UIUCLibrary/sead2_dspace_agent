require 'spec_helper'

describe Sead2DspaceAgent do
  it 'has a version number' do
    expect(Sead2DspaceAgent::VERSION).not_to be nil
  end
end

describe Sead2DspaceAgent::DspaceConnection do

  describe '.update_item_bitstream' do
    it 'streams the file' do
      @dscon = Sead2DspaceAgent::DspaceConnection.new
      @dscon.create_item 1
      expect(@dscon.update_item_bitstream('AMQP Messaging System.pptx', 'https://sead2.ncsa.illinois.edu/api/files/568c35b2e4b04a0a87bcce17/blob?key=0LBmIgHgPS', 129707)).not_to be nil
    end
  end

end
