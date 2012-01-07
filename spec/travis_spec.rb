require 'spec_helper'
SPEC_ROOT = File.dirname(__FILE__)

shared_examples_for "an abstract file_system" do

  let(:test_filename){ File.join(test_dirname,"filename.txt") }

  it "implements #exists?" do
    fs.mkdir_p(test_dirname)
    expect{ fs.open(test_filename,'w'){|f| f.write("foobar")} }.to change{ fs.exists?(test_filename) }.from(false).to(true)
  end

  it "implements #mkdir_p" do
    expect{ fs.mkdir_p(test_dirname) }.to change{ fs.directory?(test_dirname) }.from(false).to(true)
  end

  after do
    fs.rm_r(test_dirname)
  end

end

describe Swineherd::LocalFileSystem do

  it_behaves_like "an abstract file_system" do
    let(:fs){ Swineherd::LocalFileSystem.new }
    let(:test_dirname){ SPEC_ROOT+"/tmp/test_dir" }
  end

end

describe Swineherd::S3FileSystem do

  it_behaves_like "an abstract file_system" do
    let(:fs){ Swineherd::S3FileSystem.new }
    let(:test_dirname){ "swineherd-bucket-test/tmp/test_dir" }
  end

end
