
require 'yaml'
require 'logger'
require 'commander'

# Should we instead require 'rfusefs'?
require 'fusefs'

require_relative 'fuseview/version'
require_relative 'fuseview/fuseviewfs'

module McFS; module View
  
  McFS::View::Log = Logger.new(STDOUT)
  
  class FuseView
    include Commander::Methods
    
    DEFAULT_RUNFILE = ENV['HOME'] + "/.mcfs/mcfs-service.run"
    
    def initialize
      program :name, 'McFS Fuse Mounter'
      program :version, McFS::View::VERSION
      program :description, 'Multi-cloud file system mounter'

      command :mount do |cmd|
        cmd.syntax = File.basename($0) + ' mount [options] <filesystem> <mountpoint>'
        cmd.description = 'description for mount command'
        
        cmd.option '-R', '--runfile PATH', String, "Path to runtime file generated by mcfs-service (default: #{DEFAULT_RUNFILE})"
  
        cmd.action do |args, options|
          options.default runfile: DEFAULT_RUNFILE
          
          if args.size > 2
            puts args.to_yaml
            abort 'Too many arguments !'
          end
          
          if args.size == 2
            mount_at(options.runfile, args[0], args[1])
          else
            abort 'Require both filesystem and mount point !'
          end
          
        end # action
      end # :mount

      # command :unmount do |cmd|
      #   cmd.syntax = File.basename($0) + ' stop [options]'
      #   cmd.description = 'description for stop command'
      #
      #   cmd.option '-R', '--runfile PATH', String, "Path to runtime file to read (default: #{DEFAULT_RUNFILE})"
      #
      #   cmd.action do |args, options|
      #     options.default runfile: DEFAULT_RUNFILE
      #
      #     stop(args, options)
      #   end # action
      # end # :unmount
      
    end # initialize
    
    private

    def mount_at(runfile, filesystem, mountpoint)
      runtime_config = YAML.load_file(runfile)
      
      host = runtime_config['ip']
      port = runtime_config['port']
      secret = runtime_config['secret']
      
      rootfs = FuseViewFS.new(host, port, secret, filesystem)
      
      FuseFS.start(rootfs, mountpoint)
    end
    
    def start(args, options)
      if File.exists? options.runfile
        Log.error "Runfile #{options.runfile} exits."
        Process.abort
      end
      
      runtime_config = {
        'ip'      => options.listen,
        'port'    => options.port,
        'secret'  => McFS::Service::SECRET_TOKEN,
        'pid'     => Process.pid,
        'service' => File.basename($0),
        'runfile' => options.runfile
      }
      
      update_runtime_config(runtime_config)
      
      McFS::Service::RESTv1.new(runtime_config['ip'], runtime_config['port']).run
    end # start
    
    def stop(args, options)
      pid = YAML.load_file(options.runfile)['pid']
      
      # TODO: need to send QUIT signal instead and make the service
      # capture the signal and terminate gracefully
      #
      # Another method is to send a command to the service via its
      # REST endpoint, wait for some time for the process to quit
      # and then send the KILL signal as a last resort.
      Log.info "Sending INT signal to PID #{pid}"
      
      Process.kill("INT", pid)
    end # stop
    
    def update_runtime_config(runtime_config)
      
      file = runtime_config['runfile']
      
      # Create runtime config file that only the user can
      # read or write
      File.open(file, File::RDWR|File::CREAT, 0600) do |f|
        
        # Get the realpath, in case we change to a different
        # directory
        realpath = Pathname.new(file).realpath
        
        # Ensure file removal on application exit
        at_exit { File.delete realpath }
        
        # Use exclusive lock so that clients never read partial
        # configuration
        f.flock File::LOCK_EX
        
        f.write runtime_config.to_yaml
      end
    end # update_runtime_config
    
  end # class Application
  
end; end