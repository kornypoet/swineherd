module Swineherd

  #
  # Methods for interacting with Amazon's Simple Store Service (s3).
  #
  class S3FileSystem
    #    include Swineherd::BaseFileSystem

    attr_accessor :s3

    def initialize options={}
      aws_access_key = options[:aws_access_key] || Settings[:aws][:access_key]
      aws_secret_key = options[:aws_secret_key] || Settings[:aws][:secret_key]
      @s3 = RightAws::S3.new(aws_access_key, aws_secret_key)
    end

    def open path, mode="r", &blk
      S3File.new(path,mode,self,&blk)
    end

    def size path
      if directory?(path)
        ls_r(path).inject(0){|sum,file| sum += filesize(file)}
      else
        filesize(path)
      end
    end

    def rm path
      bkt,key = split_path(path)
      if key.empty? || directory?(path)
        raise Errno::EISDIR,"#{path} is a directory or bucket, use rm_r"
      else
        @s3.interface.delete(bkt, key)
      end
    end

    def rm_r path
      bkt,key = split_path(path)
      if key.empty? # only the bucket was passed in, delete it
        @s3.interface.force_delete_bucket(bkt)
      else
        if directory?(path)
          keys_to_delete = ls_r(path)
          keys_to_delete.each do |k|
            key_to_delete = key_path(k)
            @s3.interface.delete(bkt, key_to_delete)
          end
          keys_to_delete
        else
          @s3.interface.delete(bkt, key)
          [path]
        end
      end
    end

    def exists? path
      object     = File.basename(path)
      search_dir = File.dirname(path)
      if search_dir.eql?('.') # only a bucket was passed in
        begin
          (full_contents(object).size > 0)
        rescue RightAws::AwsError => error
          if error.message =~ /nosuchbucket/i
            false
          else
            raise error
          end
        end
      else
        search_dir_contents = full_contents(search_dir).map{|c| File.basename(c).gsub(/\//, '')}
        search_dir_contents.include?(object)
      end
    end

    #This is a hack. Since s3 is just a key-value store, make anything that isn't
    #already a file respond true to @directory?@
    def directory? path
      !(exists?(path) && full_contents(path).empty?)
    end

    def mv srcpath, dstpath
      src_bucket,src_key_path = split_path(srcpath)
      dst_bucket,dst_key_path = split_path(dstpath)
      mkdir_p(dstpath) unless exists?(dstpath)

      if(directory?(srcpath))
        paths_to_copy = ls_r(srcpath)
        p paths_to_copy
        common_dir    = common_directory(paths_to_copy)
        paths_to_copy.each do |path|
          src_key = key_path(path)
          dst_key = File.join(dst_key_path, path.gsub(common_dir, ''))
          @s3.interface.move(src_bucket, src_key, dst_bucket, dst_key)
        end
      else
        @s3.interface.move(src_bucket, src_key_path, dst_bucket, dst_key_path)
      end
    end

    # mv is just a special case of cp...this is a waste
    def cp srcpath, dstpath
      src_bucket,src_key_path = split_path(srcpath)
      dst_bucket,dst_key_path = split_path(dstpath)
      mkdir_p(dstpath) unless exists?(dstpath)
      if(directory?(srcpath))
        paths_to_copy = ls_r(srcpath)
        common_dir    = common_directory(paths_to_copy)
        paths_to_copy.each do |path|
          src_key = key_path(path)
          dst_key = File.join(dst_key_path, path.gsub(common_dir, ''))
          @s3.interface.copy(src_bucket, src_key, dst_bucket, dst_key)
        end
      else
        @s3.interface.copy(src_bucket, src_key_path, dst_bucket, dst_key_path)
      end
    end

    def cp_r
    end

    #This is a bit funny, there's actually no need to create a 'path' since
    #s3 is nothing more than a glorified key-value store. When you create a
    #'file' (key) the 'path' will be created for you. All we do here is create
    #the bucket unless it already exists.
    def mkdir_p path
      bkt,key = split_path(path)
      @s3.interface.create_bucket(bkt) unless exists? bkt
    end

    def ls path
      #      return unless directory?(dirpath)
      full_contents(path)
    end

    def ls_r path
      paths = ls(path)
      if paths
        paths.map{|e| ls_r(e)}.flatten
      else
        path
      end
    end

    def put srcpath, destpath
      dest_bucket = bucket(destpath)
      if File.directory?(srcpath)
        raise "NotYetImplemented"
      else
        key = srcpath
      end
      @s3.interface.put(dest_bucket, key, File.open(srcpath))
    end

    #FIXME: right now this only works on single files
    def copy_to_local srcpath, dstpath
      src_bucket,src_key_path = split_path(srcpath)
      dstfile = File.new(dstpath, 'w')
      @s3.interface.get(src_bucket, src_key_path) do |chunk|
        dstfile.write(chunk)
      end
      dstfile.close
    end

    def bucket path
      URI.parse(path).path.split('/').reject{|x| x.empty?}.first
    end

    def key_path path
      File.join(URI.parse(path).path.split('/').reject{|x| x.empty?}[1..-1])
    end

    def split_path path
      path = URI.parse(path).path.split('/').reject{|x| x.empty?}
      [path[0],path[1..-1].join("/")]
    end

    private

    #
    # Ick.
    #
    def common_directory paths
      dirs     = paths.map{|path| path.split('/')}
      min_size = dirs.map{|splits| splits.size}.min
      dirs.map!{|splits| splits[0...min_size]}
      uncommon_idx = dirs.transpose.each_with_index.find{|dirnames, idx| dirnames.uniq.length > 1}.last
      dirs[0][0...uncommon_idx].join('/')
    end

    def filesize filepath
      bucket,key = split_path(filepath)
      header = @s3.interface.head(bucket, key)
      header['content-length'].to_i
    end

    def full_contents path
      bkt,prefix = split_path(path)
      if exists?(path)
        prefix += '/' unless prefix =~ /\/$/
        contents = []
        @s3.interface.incrementally_list_bucket(bkt, {'prefix' => prefix, 'delimiter' => '/'}) do |res|
          contents += res[:common_prefixes].map{|c| File.join(bkt,c)}
          contents += res[:contents].map{|c| File.join(bkt, c[:key])}
        end
        contents
      else
        raise Errno::ENOENT, "No such file or directory - #{path}"
      end
    end

    class S3File
      attr_accessor :path, :handle, :fs

      #
      # In order to open input and output streams we must pass around the s3 fs object itself
      #
      def initialize path, mode, fs, &blk
        @fs   = fs
        @path = path
        case mode
        when "r" then
          #          raise "#{fs.type(path)} is not a readable file - #{path}" unless fs.type(path) == "file"
        when "w" then
          #          raise "Path #{path} is a directory." unless (fs.type(path) == "file") || (fs.type(path) == "unknown")
          @handle = Tempfile.new('s3filestream')
          if block_given?
            yield self
            close
          end
        end
      end

      #
      # Faster than iterating
      #
      def read
        resp = fs.s3.interface.get_object(fs.bucket(path), fs.key_path(path))
        resp
      end

      #
      # This is a little hackety. That is, once you call (.each) on the object the full object starts
      # downloading...
      #
      def readline
        @handle ||= fs.s3.interface.get_object(fs.bucket(path), fs.key_path(path)).each
        begin
          @handle.next
        rescue StopIteration, NoMethodError
          @handle = nil
          raise EOFError.new("end of file reached")
        end
      end

      def write string
        @handle.write(string)
      end

      def puts string
        write(string+"\n")
      end

      def close
        if @handle
          @handle.read
          fs.s3.interface.put(fs.bucket(path), fs.key_path(path), File.open(@handle.path, 'r'))
          @handle.close
        end
        @handle = nil
      end

    end

  end
end
