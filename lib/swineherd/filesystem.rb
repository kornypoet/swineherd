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

    # *cough* FIXME: *cough*
    def self.cp(srcpath,destpath)
      src_fs  = scheme_for(srcpath)
      dest_fs = scheme_for(destpath)
      Logger.new(STDOUT).info "#{src_fs} --> #{dest_fs}"
      if(src_fs.eql?(dest_fs))
        self.get(src_fs).cp(srcpath,destpath)
      else
        case [src_fs,dest_fs]
        when [:hdfs,:file]
          self.get(:hdfs).copy_to_local(srcpath,destpath)
        when [:hdfs,:s3]
          self.get(:hdfs).cp(srcpath,destpath)
        when [:hdfs,:s3n]
          self.get(:hdfs).cp(srcpath,destpath)
        when [:file,:hdfs]
          self.get(:hdfs).copy_from_local(srcpath,destpath)
        when [:file,:s3]
          self.get(:s3).copy_from_local(srcpath,destpath)
        when [:file,:s3]
          self.get(:s3).copy_from_local(srcpath,destpath)
        when [:s3,:hdfs]
          self.get(:hdfs).cp(srcpath,destpath)
        when [:s3n,:hdfs]
          self.get(:hdfs).cp(srcpath,destpath)
        when [:s3,:file]
          self.get(:s3).copy_to_local(srcpath,destpath)
        else
          raise "Unsupported copy between '#{src_fs}' and '#{dest_fs}' filesystems"
        end
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
