#!/usr/bin/env ruby

require 'spec_helper'
require 'yaml'

options      = YAML.load(File.read(File.dirname(__FILE__)+'/testcfg.yaml'))
current_test = options['filesystem_to_test']
describe "A '#{current_test.to_s}' filesystem instance" do

  before do
    @test_dirname   = "/tmp/test_dir"
    @test_filename  = "/tmp/test_filename.txt"
    @test_string    = "abcdefg"
    @fs = Swineherd::FileSystem.get(current_test)
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
    @fs.exists?(@test_dirname).should eql(true)
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
    copy_filename = "/tmp/test_filename2.txt"
    @fs.cp(@test_filename, copy_filename)

    @fs.exists?(@test_filename).should eql(true)
    @fs.exists?(copy_filename).should eql(true)

    @fs.rm(@test_filename)
    @fs.rm(copy_filename)
  end

  it "implements cp_r"

  it "implements mv" do
    @fs.respond_to?(:mv).should eql true
    @fs.mkdir_p(@test_dirname)
    dir2 = @test_dirname+"2"
    @fs.mv(@test_dirname, dir2)
    @fs.exists?(@test_dirname).should eql(false)
    @fs.exists?(dir2).should eql(true)
    @fs.rm_r(dir2)
  end

  it "implements ls" do
    @fs.respond_to?(:ls).should eql true
    dirs  = ['/tmp/a/','/tmp/a/b/']
    files = ['/tmp/a/d.txt','/tmp/a/b/c.txt']
    dirs.each{ |dir| @fs.mkdir_p(dir) }
    files.each{|filename| @fs.open(filename,"w"){|f|f.write(@test_string) }}
    @fs.ls('/tmp/a').class.should eql(Array)
    @fs.ls('/tmp/a').length.should eql 2
    @fs.ls('/tmp/a').include?('/tmp/a/b/c.txt').should eql false
    @fs.rm_r('/tmp/a')
  end

  it "implements ls_r" do
    @fs.respond_to?(:ls_r).should eql true
    dirs  = ['/tmp/a/','/tmp/a/b/']
    files = ['/tmp/a/d.txt','/tmp/a/b/c.txt']
    dirs.each{ |dir| @fs.mkdir_p(dir) }
    files.each{|filename| @fs.open(filename,"w"){|f|f.write(@test_string) }}
    @fs.ls_r('/tmp/a').class.should eql(Array)
    @fs.ls_r('/tmp/a').length.should eql 3
    @fs.ls_r('/tmp/a').include?('/tmp/a/b/c.txt').should eql true
    @fs.rm_r('/tmp/a')
  end

end

describe "A new file" do
  before do
    @test_filename   = "/tmp/rspec/test_filename"
    @test_filename2  = "/tmp/rspec/test_filename2"
    @test_string     = "abcdefg"

    @fs = Swineherd::FileSystem.get(current_test)
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
