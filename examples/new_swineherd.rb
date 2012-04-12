require 'swineherd'

Workflow.run(:opts => 'whatever', :working_dir => 'file://mnt/tmp') do

  # If not prepended with a prefix or a front slash, assumed to be relative to working dir
  initial_input 'path/to/some/data'

  # This calls WukongScript.new on a path assumed to scripts/count_words.rb.erb
  # and yields up a Script object with helper methods
  # without a dependency, it is assumed the input is initial
  wukong_task :count_words do
    # Options are assigned on a JOB-wide basis, so populating script variables and setting map tasks, etc.
    options { :num_tasks => 10, :buffer_size => 1204 }
    # The idempotency rule
    run(10.times)
  end

  # This calls PigScript.new on a path assumed to scripts/stack_words.pig.erb
  # and yields up a Script object with helper methods
  # input is the output of the dependency
  pig_task :stack_words => :count_words do
    options { :opts => 'whatever' }
    # the idempotency rule
    run_unless_exist
  end

  # A second task that depends on the first as well
  pig_task :stack_words_again => :count_words do
    options { :opts => 'whatever' }
    # the idempotency rule
    run_unless_exist
  end



  # This will perform a streaming job to the specified location on the input 
  storage :s3 => :stack_words do
    options { :gzip => true, :reduce_task => 1 }
    run_unless_exist
  end

end


# The Workflow object should look like this
# all tasks should have the default :opts => 'whatever', :working_dir => 'file://mnt/tmp'
# dependecy tree :s3 => :stack_words => :count_words => :initial_input

