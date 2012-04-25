module Swineherd
  class Workflow

    attr_accessor :flow_dir, :flow_name, :input, :task_to_run

    def initialize(options = {}, &blk)
      @flow_dir  = File.dirname($0)
      @flow_name = File.basename($0, '.rb').to_sym
      Swineherd.config.read(
      Swineherd.config.merge!(options)
      Swineherd.config.merge!(:flow_name => @flow_name)
      Swineherd.config.resolve!
      initial_input(options[:initial_input])
      namespace(flow_name) do
        self.instance_eval(&blk)
      end
      @task_to_run = options[:run]
    end

    def initial_input(path)
      
      @input = path
    end

    def extract_filename(definition)
      case definition
      when Symbol || String
        filename =  "#{flow_dir}/scripts/#{definition.to_s}"
      when Hash
        filename = "#{flow_dir}/scripts/#{definition.keys.first.to_s}"
      else
        raise "Invalid task definition: #{definition}"
      end
    end

    def wukong_task(definition, &blk)
      filename = extract_filename(definition) << '.rb.erb'
      script   = WukongScript.new(filename, &blk)
      create_task(script, definition)
    end

    def create_task(script, definition)
      task definition do
        script.run unless script.rules_met?
      end
    end
    
    #
    # Get next logical output of taskname by incrementing internal counter
    #
    def next_output taskname
      raise "No working directory specified, set #workdir." unless workdir
      taskcount = outputs[taskname].count
      outputs[taskname] << [workdir,flow_id,taskname].join("/")+"-#{taskcount}"
      latest_output(taskname)
    end

    #
    # Get latest output of taskname
    #
    def latest_output taskname
      outputs[taskname].last
    end

    #
    # Runs workflow starting with taskname
    #
    def run!
      p Swineherd.config
      p self
      Rake::Task[flow_name.to_s << ":" << @task_to_run.to_s].invoke
    end

    def run taskname
      task = [flow_id,taskname].join(":")
      Logger.new(STDOUT).info "Launching workflow task '#{task}'"
      Rake::Task[task].invoke
      Logger.new(STDOUT).info "Workflow task '#{task}' finished"
    end

    #
    # Describes the dependency tree of all tasks belonging to self
    #
    def describe
      Rake::Task.tasks.each do |t|
        Logger.new(STDOUT).info("Task: #{t.name} [#{t.inspect}]") if t.name =~ /#{flow_id}/
      end
    end

  end
end
