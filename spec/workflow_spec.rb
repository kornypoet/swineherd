$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__),'../lib'))

require 'swineherd'

Swineherd::Workflow.new(:foo => 'bar', :run => :my_task) do

  initial_input '/tmp/foo'

  wukong_task :other_task

  wukong_task :my_task => :other_task do
    bindings :foo       => 'qix', 
             :map_tasks => 100,
             :aws_key   => Swineherd.config[:aws][:access_key]
  end

end.run!
