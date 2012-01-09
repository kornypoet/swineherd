#!/usr/bin/env ruby

$LOAD_PATH << '../../lib'
require 'swineherd';include Swineherd

Settings.define :flow_id,     :required => true,                     :description => "Flow id required to make run of workflow unique"
Settings.define :iterations,  :type => Integer,  :default => 1,      :description => "Number of pagerank iterations to run"
#Settings.define :hadoop_home, :default => '/usr/local/share/hadoop', :description => "Path to hadoop config"
Settings.resolve!

flow = Workflow.new(Settings.flow_id) do

  # The filesystems we're going to be working with
#  hdfs    = Swineherd::FileSystem.get(:hdfs)
  localfs = Swineherd::FileSystem.get(:file)

  # The scripts we're going to use
  initializer = Script.new('scripts/pagerank_initialize.pig')
  iterator_script = Script.new('scripts/pagerank.pig')
  iterator_runner = Swineherd::Runner::PigRunner.new(iterator_script)
#  finisher    = WukongScript.new('scripts/cut_off_list.rb')
#  plotter     = RScript.new('scripts/histogram.R')

  #
  # Runs simple pig script to initialize pagerank. We must specify the input
  # here as this is the first step in the workflow. The output attribute is to
  # ensure idempotency and the options attribute is the hash that will be
  # converted into command-line args for the pig interpreter.
  #
  task :pagerank_initialize do
    output = next_output(:pagerank_initialize)
    initializer.run(:params => {:adjlist => "data/seinfeld_network.tsv", :initgrph => output},:run_mode => :local) unless localfs.exists? latest_output(:pagerank_initialize)
  end

  #
  # Runs multiple iterations of pagerank with another pig script and manages all
  # the intermediate outputs.
  #
  task :pagerank_iterate => [:pagerank_initialize] do
    iterator_runner.config.params[:damp] = '0.85f'
    iterator_runner.config.params[:curr_iter_file] = latest_output(:pagerank_initialize)
    iterator_runner.config.run_mode = :local
    Settings.iterations.times do
      iterator_runner.config.params[:next_iter_file] = next_output(:pagerank_iterate)
      iterator_runner.execute unless localfs.exists? latest_output(:pagerank_iterate)
      iterator_runner.config.params[:curr_iter_file] = latest_output(:pagerank_iterate)
    end
  end

  #
  # Here we use a wukong script to cut off the last field (a big pig bag of
  # links). Notice how every wukong script MUST have an input but pig scripts do
  # not.
  #
  task :cut_off_adjacency_list => [:pagerank_iterate] do
    finisher.input  << latest_output(:pagerank_iterate)
    finisher.output << next_output(:cut_off_adjacency_list)
    finisher.run :hadoop unless hdfs.exists? latest_output(:cut_off_adjacency_list)
  end

  #
  # We want to pull down one result file, merge the part-000.. files into one file
  #
  task :merge_results => [:cut_off_adjacency_list] do
    merged_results = next_output(:merge_results)
    hdfs.merge(latest_output(:cut_off_adjacency_list), merged_results) unless hdfs.exists? merged_results
  end

  #
  # Cat results into a local directory with the same structure
  # eg. #{work_dir}/#{flow_id}/pull_down_results-0.
  #
  # FIXME: Bridging filesystems is cludgey.
  #
  task :pull_down_results => [:merge_results] do
    local_results = next_output(:pull_down_results)
    hdfs.copy_to_local(latest_output(:merge_results), local_results) unless localfs.exists? local_results
  end

  #
  # Plot 2nd column of the result as a histogram (requires R and
  # ggplot2). Note that the output here is a png file but doesn't have that
  # extension. Ensmarten me as to the right way to handle that?
  #
  task :plot_results =>  [:pull_down_results] do
    plotter.attributes = {
      :pagerank_data => latest_output(:pull_down_results),
      :plot_file     => next_output(:plot_results), # <-- this will be a png...
      :raw_rank      => "aes(x=d$V2)"
    }
    plotter.run(:hadoop) unless localfs.exists? latest_output(:plot_results)
  end

end

flow.workdir = File.join(File.dirname(__FILE__),"pagerank_example")
#flow.describe
flow.run(:pagerank_iterate)
