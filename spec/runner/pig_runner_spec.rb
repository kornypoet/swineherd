require 'spec_helper'

describe 'Swineherd::Runner::PigRunner' do
  before {
    script_path = File.join(File.dirname(__FILE__),'../foo.pig.erb')
    script = Swineherd::Script.new(script_path,:in_path => 'fips_to_state.tsv')
    @runner = Swineherd::Runner.for_script(script)
  }

  context 'HadoopJobConf' do
    it 'should set -D jobconf options' do
      @runner.config.map_tasks = 10
      @runner.jobconf_options.should include '-Dmapred.map.tasks=10'
      @runner.config.map_tasks = 20
      @runner.jobconf_options.should_not include '-Dmapred.map.tasks=10'
      @runner.jobconf_options.should include '-Dmapred.map.tasks=20'
    end
  end

  context 'PigJobConf' do
    it 'should set -D jobconf options' do
      @runner.config.combine_splits = false
      @runner.pig_jobconf_options.should include '-Dpig.splitCombination=false'
      @runner.config.combine_splits = true
      @runner.pig_jobconf_options.should_not include '-Dpig.splitCombination=false'
      @runner.pig_jobconf_options.should include '-Dpig.splitCombination=true'
    end

    it 'should set -p command line params' do
      @runner.config.params = {:foo => "bar"}
      @runner.param_options_string.should include '-p FOO=bar'
    end

    it 'should set -exectype run mode' do
      @runner.config.run_mode = 'local'
      @runner.run_mode.should == '-exectype local'

      @runner.config.run_mode = 'mapreduce'
      @runner.run_mode.should == '-exectype mapreduce'
    end

  end
end
