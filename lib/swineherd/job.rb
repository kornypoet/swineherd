module Swineherd
  class Job

    attr_accessor :job_id, :name, :script

    def initialize(definition, script)
      @job_id = id
      create_rake_task(definition)
    end

    def create_rask_task
      task(definition) do
        @script.run
      end
    end

  end
end
