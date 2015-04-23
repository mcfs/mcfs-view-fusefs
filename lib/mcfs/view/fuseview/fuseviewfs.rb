
# TODO: we probably need to use a proper rest client
require 'net/http'

module McFS; module View
  class FuseViewFS < FuseFS::FuseDir
    
    def initialize(host, port, secret, filesystem)
      @host = host
      @port = port
      @secret = secret
      @filesystem = filesystem
      
      @http = Net::HTTP.new(@host, @port)
    end
    
    def contents(dir)
      dir_request = {
        'filesystem' => @filesystem,
        'dir'        => dir
      }
      
      YAML.load(@http.post('/api/v1/filesystems/list', dir_request.to_yaml).body)
    end
    
  end # FuseViewFS
  
end; end

