module Swineherd
  class Script

    attr_reader   :raw_script_filename
    attr_accessor :binding

    def initialize(raw_script_filename,binding={})
      @raw_script_filename = raw_script_filename
      @binding = binding
    end

    def run(settings={})
      runner = Swineherd::Runner.for_script(self)
      runner.config.merge!(settings)
      runner.execute
    end

    def bind(key_val={})
      @binding.merge!(key_val)
    end

    def flush!
      File.delete(filename)
      @file     = nil
      @binding  = {}
    end

    def file
      @file ||= File.open(script_filename,"w+"){|file| file.write(script_contents);file}
    end

    def filename
      file.path
    end

    private

    def script_filename
      Settings.template_root+[Time.now.to_i,$$,File.basename(raw_script_filename).gsub(/.erb$/,'')].join("-")
    end

    def script_contents
      Erubis::Eruby.new(File.read(raw_script_filename)).result(self.binding)
    end

  end
end
