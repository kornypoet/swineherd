
module Swineherd
  class Script

    attr_reader   :raw_script_filename,:file
    attr_accessor :binding

    def initialize(raw_script_filename,binding={})
      @raw_script_filename = raw_script_filename
      @binding = binding
    end

    def run(settings={})
      runner.config.merge!(settings)
      runner.execute
    end

    def runner
      @runner ||= Swineherd::Runner.for_script(self)
    end

    def flush!
      File.delete(filename)
      @file     = nil
      @binding  = {}
    end

    def filename
      write
      file && file.path
    end

    def write
      @file ||= File.open(script_filename,"w+"){|file| file.write(script_contents);file}
    end

    private

    def script_filename
      Swineherd.config.template_root+[Time.now.to_i,$$,File.basename(raw_script_filename).gsub(/.erb$/,'')].join("-")
    end

    def script_contents
      Erubis::Eruby.new(File.read(raw_script_filename)).result(self.binding)
    end

  end
end

require 'swineherd/script/pig_script'
