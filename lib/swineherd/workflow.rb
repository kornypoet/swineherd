Swineherd.config.define :flow_id,     :required => true,                     :description => "Flow id required to make run of workflow unique"
Swineherd.config.define :iterations,  :type => Integer,  :default => 10,      :description => "Number of pagerank iterations to run"

module Swineherd
  class Workflow
    attr_accessor :workdir,:outputs,:flow_id

    #
    # Create a new workflow and new namespace for this workflow
    #
    def initialize flow_id, &blk
      @flow_id = flow_id
      @outputs = Hash.new{|h,k| h[k] = []}
      namespace flow_id do
        self.instance_eval(&blk)
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
