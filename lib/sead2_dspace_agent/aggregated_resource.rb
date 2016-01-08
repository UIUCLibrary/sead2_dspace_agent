
module Sead2DspaceAgent

  class AggregatedResource

    attr_accessor :title, :file_url, :date, :mime

    def initialize(ar)
      @file_url = ar['similarTo']
      @title = ar['Title']
      @mime = ar['Mimetype']
      @date = ar['Date']
    end

  end

end