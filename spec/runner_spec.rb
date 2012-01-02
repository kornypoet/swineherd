require 'spec_helper'

describe 'Swineherd::Runner' do
  context 'should return the correct runner klass' do
    specify 'for foo.pig.erb' do
      script = Swineherd::Script.new('foo.pig.erb')
      runner = Swineherd::Runner.for_script(script)
      runner.class.should == Swineherd::Runner::PigRunner
    end
    specify 'for foo.pig' do
      script = Swineherd::Script.new('foo.pig')
      runner = Swineherd::Runner.for_script(script)
      runner.class.should == Swineherd::Runner::PigRunner
    end
  end
end
