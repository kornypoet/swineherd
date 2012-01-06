module Swineherd
  class LocalFileSystem
#    include Swineherd::BaseFileSystem

    def initialize *args
    end

    def open path, mode="r", &blk
      File.open(path,mode,&blk)
    end

    #Globs for files at @path@, append '**/*' to glob recursively
    def size path
      Dir[path].inject(0){|s,f|s+=File.size(f)}
    end

    def rm_r path
      FileUtils.rm_r path
    end

    def rm path
      FileUtils.rm path
    end

    def exists? path
      File.exists?(path)
    end

    def directory? path
      File.directory? path
    end

    def mv srcpath, dstpath
      FileUtils.mv(srcpath,dstpath)
    end

    def cp srcpath, dstpath
      FileUtils.cp(srcpath,dstpath)
    end

    def cp_r srcpath, dstpath
      FileUtils.cp_r(srcpath,dstpath)
    end

    def mkdir_p path
      FileUtils.mkdir_p path
    end

    #Globs for files at @path@, append '**/*' to glob recursively
    def entries path
      Dir[path]
    end

  end
end
