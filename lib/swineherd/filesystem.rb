require 'fileutils'

require 'swineherd/filesystem/basefilesystem'
require 'swineherd/filesystem/localfilesystem'
require 'swineherd/filesystem/hadoopfilesystem'
require 'swineherd/filesystem/s3filesystem'

module Swineherd
  module FileSystem

    HDFS_PREFIX_REGEXP = /^hdfs:\/\//
    S3_PREFIX_REGEXP   = /^s3n?:\/\//

    FILESYSTEMS = {
      'file' => Swineherd::LocalFileSystem,
      'hdfs' => Swineherd::HadoopFileSystem,
      's3'   => Swineherd::S3FileSystem
    }

    # A factory function that returns an instance of the requested class
    def self.get scheme, *args
      begin
        FILESYSTEMS[scheme.to_s].new *args
      rescue NoMethodError => e
        raise "Filesystem with scheme #{scheme} does not exist.\n #{e.message}"
      end
    end

    private

    # def instance_for file_path
    #   if file_path =~ HDFS_PREFIX_REGEXP
    #     Swineherd::HadoopFileSystem.new
    #   elsif file_path =~ S3_PREFIX_REGEXP
    #     Swineherd::S3FileSystem.new
    #   else
    #     Swineherd::LocalFileSystem.new
    #   end
    # end

  end
end
