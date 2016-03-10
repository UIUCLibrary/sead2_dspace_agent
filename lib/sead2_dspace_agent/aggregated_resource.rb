
module Sead2DspaceAgent

  class AggregatedResource

    attr_accessor :title, :size, :file_url, :date, :mime

    def initialize(ar)
      @file_url = ar['similarTo']
      @title = ar['Title']
      @size = ar['Size']
      @mime = ar['Mimetype']
      @date = ar['Date']
    end

  end

end