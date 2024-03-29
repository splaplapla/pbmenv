# frozen_string_literal: true

module Pbmenv
  class CreateVersionService
    class AlreadyCreatedError < StandardError; end
    class NotSupportVersionError < StandardError; end

    attr_accessor :version, :use_option, :enable_pbm_cloud

    def initialize(version: , use_option: , enable_pbm_cloud: )
      self.version = version
      self.use_option = use_option
      self.enable_pbm_cloud = enable_pbm_cloud
    end

    def execute!
      pathname = VersionPathname.new(version)
      if File.exist?(pathname.version_path)
        raise AlreadyCreatedError
      end

      begin
        download_src(version)
        build_app_file
        create_if_miss_shared_dir
        create_if_miss_device_id_file
        link_device_id_file(version: version)
        create_if_miss_current_dir(version: version)
      rescue DownloadSrcService::DownloadError
        puts "Download failed. Check the version name."
        raise NotSupportVersionError
      rescue => e
        Helper.system_and_puts "rm -rf #{pathname.version_path}"
        raise
      ensure
        if Dir.exist?(pathname.src_pbm_path)
          Helper.system_and_puts "rm -rf #{pathname.src_pbm_path}"
        end
      end

      return true
    end

    private

    # @return [String]
    def download_src(version)
      Pbmenv::DownloadSrcService.new(version).execute!
    end

    def build_app_file
      pathname = VersionPathname.new(version)
      unless Helper.system_and_puts "mkdir -p #{pathname.version_path}"
        raise "Insufficient permissions..."
      end

      Helper.system_and_puts "cp -r #{pathname.src_project_template_systemd_units} #{pathname.version_path}/"

      if File.exist?(pathname.src_pbm_project_template_app_rb_erb_path)
        pathname.project_template_file_paths(include_app_erb: true).each do |project_template_file_path|
          Helper.system_and_puts "cp #{project_template_file_path} #{pathname.version_path}/"
        end
        require pathname.lib_app_generator
        AppGenerator.new(
          prefix_path: pathname.version_path,
          enable_integration_with_pbm_cloud: enable_pbm_cloud,
        ).generate
        Helper.system_and_puts "rm #{pathname.app_rb_erb_path}"
      else
        pathname.project_template_file_paths(include_app_erb: false).each do |project_template_file_path|
          Helper.system_and_puts "cp #{project_template_file_path} #{pathname.version_path}/"
        end

        # 旧実装バージョン. 0.2.10くらいで削除する
        if enable_pbm_cloud
          text = File.read(pathname.app_rb_path)
          if text =~ /config\.api_servers\s+=\s+\['(https:\/\/.+)'\]/ && (url = $1)
            text.gsub!(/#\s+config\.api_servers\s+=\s+.+$/, "config.api_servers = '#{url}'")
          end
          File.write(pathname.app_rb_path, text)
        end
      end
    end

    def create_if_miss_shared_dir
      return if File.exist?(VersionPathname.shared)

      Helper.system_and_puts <<~SHELL
          mkdir -p #{VersionPathname.shared}
      SHELL
    end

    def create_if_miss_device_id_file
      device_id_path_in_shared = VersionPathname.device_id_path_in_shared
      return if File.exist?(device_id_path_in_shared)

      File.write(device_id_path_in_shared, "d_#{SecureRandom.uuid}")
    end

    def link_device_id_file(version: )
      pathname = VersionPathname.new(version)
      Helper.system_and_puts <<~SHELL
        ln -s #{pathname.device_id_path_in_shared} #{pathname.device_id_path_in_version}
      SHELL
    end

    def create_if_miss_current_dir(version: )
      # 初回だけinstall時にcurrentを作成する
      if !File.exist?(VersionPathname.current) || use_option
        UseVersionService.new(version: version).execute!
      end
    end
  end
end
