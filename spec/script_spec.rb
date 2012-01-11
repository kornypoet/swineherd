load 'spec_helper.rb'

describe 'Swineherd::Script' do
  context 'a new script' do

    let(:script_path){File.join(File.dirname(__FILE__),'foo.pig.erb')}
    let(:script){Swineherd::Script.new(script_path,:in_path => 'fips_to_state.tsv')}

    it 'should evaluate script with variable bindings' do
      script.evaluated_script_contents.should eql "fips = LOAD 'fips_to_state.tsv' AS (fips_id:int,state_name:chararray);\nDUMP fips;\n"
    end

    it 'should allow bound script variables to be changed on flush' do
      expect{
        script.flush!
        script.binding[:in_path] = "foo_bar_baz.tsv"
      }.to change{script.evaluated_script_contents}.from("fips = LOAD 'fips_to_state.tsv' AS (fips_id:int,state_name:chararray);\nDUMP fips;\n").to("fips = LOAD 'foo_bar_baz.tsv' AS (fips_id:int,state_name:chararray);\nDUMP fips;\n")
    end

    it "should write a templated file to disk" do
      expect{script.write}.to change{File.exists?(script.filename)}.from(false).to(true)
    end

  end
end
