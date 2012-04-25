module Swineherd
  class Script

    attr_accessor :binding, :raw_script_filename

    def initialize(filename, &blk)
      @raw_script_filename = filename
      @binding = {} 
      self.instance_eval(&blk) if blk
    end

    def bindings(hsh={})
      @binding = Swineherd.config.merge(hsh)
    end

    def evaluated_script_contents
      Erubis::Eruby.new(File.read(raw_script_filename)).result(binding)
    end

    def swineherd_input
      Rake::Task[Swineherd.config[:flow_name].to_s << ':' << File.basename(raw_script_filename, '.rb.erb')].prerequisites
    end

    def swineherd_output
      File.join(Swineherd.config[:output_root], Swineherd.config[:flow_name].to_s, File.basename(raw_script_filename), 'output')
    end
    
    def rules_met?
      binding[:runit]
    end
    
    def run(settings={})
      binding.merge!(:output => swineherd_output, :input => swineherd_input)
      write
      Log.info("\n" << evaluated_script_contents) if Swineherd.config.verbose == true 
      # runner.config.merge!(settings)
      # runner.execute
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
      @template_filename ||= File.join(Swineherd.config.template_dir, [Time.now.to_i, $$, File.basename(raw_script_filename).gsub(/.erb$/,'')].join("-"))
    end

    private

    def template_file
      @template_file ||= File.open(filename, "w+"){ |file| file.write(evaluated_script_contents) ; file }
    end

  end
end
