require 'spec_helper'

describe "Swineherd" do

  shared_examples_for "an abstract file_system" do

    it { should respond_to(:exists?).with(1).arguments }

  end
 
  describe Swineherd::LocalFileSystem do
   
    it_behaves_like "an abstract file_system"

  end
  
  describe Swineherd::S3FileSystem do

    it_behaves_like "an abstract file_system"

  end

end
