#!/usr/bin/env ruby

require 'spec_helper'

[:file,:s3,:hdfs].each do |filesystem|

  describe "A '#{filesystem.to_s}' filesystem instance" do

    before do
      @fs = Swineherd::FileSystem.get(filesystem)
      test_bucket = "swineherd-test-bucket" #FIXME: this doesn't belong here
      @test_dirname   = (filesystem == :s3) ? "#{test_bucket}/tmp/test_dir" : "/tmp/test_dir"
      @test_filename  = (filesystem == :s3) ? "#{test_bucket}/tmp/test_filename.txt" : "/tmp/test_filename.txt"

      @dirs  = ['/tmp/a','/tmp/a/b']
      @files = ['/tmp/a/d.txt','/tmp/a/b/c.txt']

      @dirs.map!{|dir| dir = test_bucket+dir } if filesystem == :s3
      @files.map!{|file| file = test_bucket+file } if filesystem == :s3

      @test_string    = "abcdefg"

    end

    it "implements exists?" do
      @fs.respond_to?(:exists?).should eql(true)
    end

    it "implements directory?" do
      @fs.respond_to?(:directory?).should eql(true)

      @fs.mkdir_p(@test_dirname)
      @fs.directory?(@test_dirname).should eql true

      @fs.open(@test_filename, 'w'){|f| f.write(@test_string)}
      @fs.directory?(@test_filename).should eql false

      @fs.rm_r(@test_dirname)
      @fs.rm(@test_filename)
    end

    it "implements mkdir_p" do
      @fs.respond_to?(:mkdir_p).should eql(true)
      @fs.mkdir_p(@test_dirname)
      @fs.directory?(@test_dirname).should eql(true)
    end

    it "implements rm" do
      @fs.respond_to?(:rm).should eql(true)

      @fs.open(@test_filename, 'w'){|f| f.write(@test_string)}
      @fs.exists?(@test_filename).should eql true
      @fs.rm(@test_filename)
      @fs.exists?(@test_filename).should eql false

      @fs.mkdir_p(@test_dirname)
      lambda{@fs.rm(@test_dirname)}.should raise_error

      @fs.rm_r(@test_dirname)
    end

    it "implements rm_r" do
      @fs.respond_to?(:rm_r).should eql(true)
      @fs.mkdir_p(@test_dirname)
      @fs.rm_r(@test_dirname)
      @fs.exists?(@test_dirname).should eql(false)
    end

    it 'implements open' do
      @fs.respond_to?(:open).should eql(true)
      file = @fs.open(@test_filename, 'w')
      file.write(@test_string)
      file.close
      @fs.exists?(@test_filename).should eql true
      (@test_string.length).should eql(@fs.size(@test_filename))
      @fs.rm(@test_filename)
    end

    it 'implements open with &blk' do
      @fs.respond_to?(:open).should eql true
      @fs.open(@test_filename, 'w'){|f| f.write(@test_string)}
      @fs.exists?(@test_filename).should eql true
      (@test_string.length).should eql(@fs.size(@test_filename))
      @fs.rm(@test_filename)
    end

    it "implements size" do
      @fs.respond_to?(:size).should eql true
      @fs.open(@test_filename, 'w'){|f| f.write(@test_string)}
      (@test_string.length).should eql(@fs.size(@test_filename))
      @fs.rm(@test_filename)
    end

    it "implements cp" do
      @fs.respond_to?(:cp).should eql true
      @fs.open(@test_filename, 'w'){|f| f.write(@test_string)}
      filename2 = File.join(File.dirname(@test_filename),File.basename(@test_filename,".txt")+"2.txt")
      @fs.cp(@test_filename, filename2)

      @fs.exists?(@test_filename).should eql(true)
      @fs.exists?(filename2).should eql(true)

      @fs.rm(@test_filename)
      @fs.rm(filename2)
    end

    it "implements cp_r"

    it "implements mv" do
      @fs.respond_to?(:mv).should eql true
      @fs.open(@test_filename, 'w'){|f| f.write(@test_string)}
      filename2 = File.join(File.dirname(@test_filename),File.basename(@test_filename,".txt")+"2.txt")
      @fs.mv(@test_filename, filename2)
      @fs.exists?(@test_filename).should eql(false)
      @fs.exists?(filename2).should eql(true)
      @fs.rm(filename2)
    end

    it "implements ls" do
      @fs.respond_to?(:ls).should eql true
      @dirs.each{ |dir| @fs.mkdir_p(dir) }
      @files.each{|filename| @fs.open(filename,"w"){|f|f.write(@test_string) }}
      @fs.ls(@dirs[0]).class.should eql(Array)
      @fs.ls(@dirs[0]).length.should eql 2
      @fs.ls(@dirs[0]).include?(@files[1]).should eql false
      @fs.rm_r(@dirs[0])
    end

    it "implements ls_r" do
      @fs.respond_to?(:ls_r).should eql true
      @dirs.each{ |dir| @fs.mkdir_p(dir) }
      @files.each{|filename| @fs.open(filename,"w"){|f|f.write(@test_string) }}
      @fs.ls_r(@dirs[0]).class.should eql(Array)
      p @dirs[0]
      @fs.ls_r(@dirs[0]).length.should eql 3

      @fs.ls_r(@dirs[0]).include?(@files[1]).should eql true
      @fs.rm_r(@dirs[0])
    end

    describe "with a new file" do
      before do
        @fs.rm(@test_filename) if @fs.exists?(@test_filename)
        @file = @fs.open(@test_filename,'w')
      end

      it "implements path" do
        @file.respond_to?(:path).should eql true
        @file.path.should eql @test_filename
      end

      it "implements close" do
        @file.respond_to?(:close).should eql true
        @file.write(@test_string)
        @file.close
        lambda{@file.write(@test_string)}.should raise_error
      end

      it "implements write" do
        @file.respond_to?(:write).should eql true
        @file.write(@test_string)
        @file.close
        @fs.rm(@file.path)
      end

      it "implements read" do
        @file.respond_to?(:read).should eql true
        @file.write(@test_string)
        @file.close

        @file_r = @fs.open(@file.path,"r")
        @file_r.read.should eql(@test_string)

        @fs.rm(@file_r.path)
      end

    end

  end
end
