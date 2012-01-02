load 'spec_helper.rb'

describe 'Swineherd::Script' do
  context 'a new script' do
    before {
      script_path = File.join(File.dirname(__FILE__),'foo.pig.erb')
      @script = Swineherd::Script.new(script_path,:in_path => 'fips_to_state.tsv')
    }

    it 'should instantiate an ERB script with variable bindings' do
      @script.contents.should == "fips = LOAD 'fips_to_state.tsv' AS (fips_id:int,state_name:chararray);\nDUMP fips;\n"
    end

    it 'should write a file' do
      @script.write
      File.exists?(@script.filename).should be_true
    end

    it 'should delete file on flush' do
      @script.write
      @script.flush!
      File.exists?(@script.filename).should be_false
    end

  end
end
