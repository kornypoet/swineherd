require 'erubis'

module Swineherd
  class Script

    attr_reader   :raw_script_filename
    attr_accessor :contents,:variables

    def initialize(raw_script_filename,variables={})
      @raw_script_filename = raw_script_filename
      @variables = variables
    end

    def run(settings={})
      write unless @file
      runner = Swineherd::Runner.for_script(self)
      runner.config.merge!(settings)
      runner.execute
    end

    def contents
      @contents ||= Erubis::Eruby.new(File.read(raw_script_filename)).result(variables)
    end

    def flush!
      File.delete(filename)
      @contents = nil
      @filename = nil
      @file     = nil
    end

    def filename
      @filename ||= "/tmp/"+[Time.now.to_i,$$,File.basename(raw_script_filename).gsub(/.erb$/,'')].join("-")
    end

    def write
      @file ||= File.open(filename,"w+"){ |file| file.write(contents);file}
    end

  end
end
