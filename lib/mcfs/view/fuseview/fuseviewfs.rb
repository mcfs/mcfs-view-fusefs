
# TODO: we probably need to use a proper rest client
require 'net/http'

module McFS; module View
  class FuseViewFS < FuseFS::FuseDir
    
    def initialize(host, port, secret, filesystem)
      Log.info "FuseViewFS initializing for #{@filesystem}@#{host}:#{port}"
      
      @host = host
      @port = port
      @secret = secret
      @filesystem = filesystem
      
      @http = Net::HTTP.new(@host, @port)
    end
    
    def contents(dir)
      Log.info "#{@filesystem}: contents #{dir}"
      
      dir_request = {
        'filesystem' => @filesystem,
        'directory'  => dir
      }
      
      YAML.load(@http.post('/api/v1/filesystems/browse', dir_request.to_yaml).body)
    end
    
    def metadata(path)
      Log.info "#{@filesystem}: metadata #{path}"
      
      metadata_request = {
        'filesystem' => @filesystem,
        'path' => path
      }
      
      YAML.load(@http.post('/api/v1/filesystems/metadata', metadata_request.to_yaml).body)
    end
    
    def directory?(path)
      Log.info "#{@filesystem}: directory? #{path}"
      
      if meta = metadata(path)
        meta['type'] == :directory
      else
        false
      end
    end
    
    def file?(path)
      Log.info "#{@filesystem}: file? #{path}"
      
      if meta = metadata(path)
        meta['type'] == :file
      else
        false
      end
    end
    
    def executable?(path)
      Log.info "#{@filesystem}: executable? #{path}"
      
      directory? path
    end
    
    def size(path)
      Log.info "#{@filesystem}: size? #{path}"
      
      metadata(path)['size']
    end
    
    def read_file(path)
      Log.info "#{@filesystem}: read_file? #{path}"
      
      readfile_request = {
        'filesystem' => @filesystem,
        'path' => path
      }
      
      YAML.load(@http.post('/api/v1/filesystems/readfile', readfile_request.to_yaml).body)
    end
    
    def can_write?(path)
      Log.info "#{@filesystem}: can_write? #{path}"
      
      true
    end
    
    def write_to(path, str)
      Log.info "#{@filesystem}: write_to? #{path}"
      
      writefile_request = {
        'filesystem' => @filesystem,
        'path' => path,
        'data' => str
      }
      
      
      @http.post('/api/v1/filesystems/writefile', writefile_request.to_yaml)
    end
    
    def can_mkdir?(path)
      Log.info "#{@filesystem}: can_mkdir? #{path}"
      
      true
    end
    
    def mkdir(path)
      Log.info "#{@filesystem}: mkdir #{path}"
      
      mkdir_request = {
        'filesystem' => @filesystem,
        'path' => path
      }
      
      @http.post('/api/v1/filesystems/mkdir', mkdir_request.to_yaml)
    end
        
    def can_delete?(path)
      Log.info "#{@filesystem}: can_delete? #{path}"
      
      true
    end
    
    def delete(path)
      Log.info "#{@filesystem}: delete #{path}"
      
      delete_request = {
        'filesystem' => @filesystem,
        'path' => path
      }
      
      @http.post('/api/v1/filesystems/delete', delete_request.to_yaml)
    end
    
    def can_rmdir?(path)
      Log.info "#{@filesystem}: can_rmdir? #{path}"
      
      true
    end
    
    alias_method :rmdir, :delete
    
  end # FuseViewFS
  
end; end

