module Swineherd
  class Script

    attr_reader   :raw_script_filename
    attr_accessor :binding

    def initialize(raw_script_filename,binding={})
      @raw_script_filename = raw_script_filename
      @binding = binding
    end

    def run(settings={})
      write
      runner.config.merge!(settings)
      #Logger.new(STDOUT).info "\n#{evaluated_script_contents}"
      runner.execute
    end

    def runner
      @runner ||= Swineherd::Runner.for_script(self)
    end

    def flush!
      File.delete(filename) if File.exists?(filename)
      @template_filename = nil
      @template_file = nil
      @binding = {}
    end

    def write
      template_file
    end

    def filename
      @template_filename ||= Swineherd.config.template_root+[Time.now.to_i,$$,File.basename(raw_script_filename).gsub(/.erb$/,'')].join("-")
    end

    def evaluated_script_contents
      Erubis::Eruby.new(File.read(raw_script_filename)).result(self.binding)
    end

    private

    def template_file
      @template_file ||= File.open(filename,"w+"){|file| file.write(evaluated_script_contents);file}
    end

  end
end

require 'swineherd/script/pig_script'
