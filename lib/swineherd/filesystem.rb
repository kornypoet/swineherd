require 'fileutils'
require 'tempfile'
require 'right_aws'

require 'swineherd/filesystem/basefilesystem'
require 'swineherd/filesystem/localfilesystem'
require 'swineherd/filesystem/hadoopfilesystem'
require 'swineherd/filesystem/s3filesystem'

module Swineherd
  module FileSystem

    HDFS_SCHEME_REGEXP = /^hdfs:\/\//
    S3_SCHEME_REGEXP   = /^s3n?:\/\//

    FILESYSTEMS = {
      'file' => Swineherd::LocalFileSystem,
      'hdfs' => Swineherd::HadoopFileSystem,
      's3'   => Swineherd::S3FileSystem,
      's3n'  => Swineherd::S3FileSystem
    }

    # A factory function that returns an instance of the requested class
    def self.get scheme, *args
      begin
        FILESYSTEMS[scheme.to_s].new *args
      rescue NoMethodError => e
        raise "Filesystem with scheme #{scheme} does not exist.\n #{e.message}"
      end
    end

    def self.exists?(path)
      fs = self.get(scheme_for(path))
      Logger.new(STDOUT).info "Using #{fs.class}"
      fs.exists?(path)
    end

    def self.cp(srcpath,destpath)
      src_fs  = scheme_for(srcpath)
      dest_fs = scheme_for(destpath)
      Logger.new(STDOUT).info "#{src_fs} --> #{dest_fs}"
      if(src_fs.eql?(dest_fs))
        self.get(src_fs).cp(srcpath,destpath)
      elsif src_fs.eql?(:file)
        self.get(dest_fs).copy_from_local(srcpath,destpath)
      elsif dest_fs.eql?(:file)
        self.get(src_fs).copy_to_local(srcpath,destpath)
      else #cp between s3/s3n and hdfs can be handled by Hadoop:FileUtil in HadoopFileSystem
        self.get(:hdfs).cp(srcpath,destpath)
      end
    end

    private

    #defaults to local filesystem :file
    def self.scheme_for(path)
      scheme = URI.parse(path).scheme
      (scheme && scheme.to_sym) || :file
    end

  end
end
