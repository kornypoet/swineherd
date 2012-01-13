module Swineherd

  #
  # Job class is at its core a rake task
  #
  class Job

    attr_accessor :name,:script,:dependencies,:job_id

    def initialize job_id, &blk
      @job_id       = job_id
      @dependencies = []
      self.instance_eval(&blk)
      raketask
      handle_dependencies
    end

    def handle_dependencies
      return if dependencies.empty?
      task name => dependencies
    end

    def cmd
      @script.runner.command_line
    end

    #
    # Every job is compiled into a rake task
    #
    def raketask
      task name do
        @script.run
      end
    end
  end
end
