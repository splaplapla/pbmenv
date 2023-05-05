module Pbmenv
  class CLI
    class CLIError < StandardError; end

    def self.run(argv)
      sub_command = argv[0]
      case sub_command
      when 'available_versions', 'av'
        Pbmenv.available_versions.each { |x| puts x }
      when 'versions', 'list'
        Pbmenv.versions.each { |x| puts x }
      when 'install', 'i'
        sub_command_arg = argv[1]
        use_option = false
        case argv[2]
        when "--use"
          use_option = true
        when nil
        else
          puts <<~EOH
            Unknown option:
              available options: --use
          EOH
          raise CLIError
        end

        Pbmenv.install(sub_command_arg, use_option: use_option)
      when 'use', 'u'
        sub_command_arg = argv[1]
        Pbmenv.use(sub_command_arg)
      when 'uninstall'
        sub_command_arg = argv[1]
        Pbmenv.uninstall(sub_command_arg)
      when 'clean'
        version_size_to_keep = argv[1].to_i
        if version_size_to_keep == 0
          version_size_to_keep = 10
        end
        Pbmenv.clean(version_size_to_keep)
      when '--version'
        puts Pbmenv::VERSION
      else
        puts <<~EOH
          Unknown command:
            available commands: available_versions, versions, install, use, uninstall, clean
        EOH
        raise CLIError
      end
    end
  end
end
