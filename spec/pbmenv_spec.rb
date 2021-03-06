require "spec_helper"

describe Pbmenv do
  def purge_pbm_dir
    `rm -rf /usr/share/pbm`
  end

  before do
    raise("ファイルを読み書きするのでmacではやらない方がいいです") unless ENV["CI"]
  end

  before(:each) do
    allow(Pbmenv::Helper).to receive(:to_stdout) if ENV["DISABLE_DEBUG_LOG"]
    purge_pbm_dir
  end

  describe 'integration' do
    subject do
      Pbmenv.install(target_version)
      Pbmenv.use(target_version)
    end

    context '0.2.1を渡すとき' do
      let(:target_version) { "0.2.1" }

      it 'currentにシムリンクが貼っている' do
        expect(subject).to eq(true)
        latest_version = Pbmenv.available_versions.first
        version_path = "/usr/share/pbm/v#{latest_version}"
        expect(File.readlink("/usr/share/pbm/current")).to eq("/usr/share/pbm/v#{target_version}")
        expect(Dir.exists?(version_path)).to eq(true)
        expect(File.exists?("#{version_path}/app.rb")).to eq(true)
        expect(File.exists?("#{version_path}/README.md")).to eq(true)
        expect(File.exists?("#{version_path}/setting.yml")).to eq(true)
        expect(Dir.exists?("/usr/share/pbm/shared")).to eq(true)
        expect(File.read("/usr/share/pbm/shared/device_id")).to be_a(String)
      end
    end

    context '存在しないバージョンを渡すとき' do
      let(:target_version) { "999.999.999" }

      it do
        expect(subject).to eq(false)
      end
    end

    context 'latestを渡すとき' do
      let(:target_version) { "latest" }

      it 'currentにシムリンクが貼っている' do
        subject
        latest_version = Pbmenv.available_versions.first
        version_path = "/usr/share/pbm/v#{latest_version}"
        expect(File.readlink("/usr/share/pbm/current")).to match(%r!/usr/share/pbm/v[\d.]+!)
        expect(Dir.exists?(version_path)).to eq(true)
        expect(File.exists?("#{version_path}/app.rb")).to eq(true)
        expect(File.exists?("#{version_path}/README.md")).to eq(true)
        expect(File.exists?("#{version_path}/setting.yml")).to eq(true)
        expect(Dir.exists?("/usr/share/pbm/shared")).to eq(true)
        expect(File.read("/usr/share/pbm/shared/device_id")).to be_a(String)
      end
    end
  end

  describe '.use' do
    context 'すでにインストール済みのとき', :with_decompress_procon_pbm_man do
      let(:decompress_procon_pbm_man_versions) { ["0.1.5", "0.1.6"] }

      before(:each) do
        Pbmenv.install("0.1.5")
        Pbmenv.install("0.1.6")
      end

      context 'バージョンを渡すとき' do
        subject { Pbmenv.use("0.1.6") }

        it 'currentにシムリンクが貼っている' do
          subject
          expect(File.readlink("/usr/share/pbm/current")).to eq("/usr/share/pbm/v0.1.6")
        end

        context 'インストールしていないバージョンをuseするとき' do
          it 'currentのシムリンクを更新しない' do
            subject
            Pbmenv.use("0.1.7")
            expect(File.readlink("/usr/share/pbm/current")).to eq("/usr/share/pbm/v0.1.6")
          end
        end

        context 'プレフィックスにvが付いているとき' do
          it 'currentにシムリンクを貼る' do
            subject
            Pbmenv.use("v0.1.6")
            expect(File.readlink("/usr/share/pbm/current")).to eq("/usr/share/pbm/v0.1.6")
          end
        end
      end

      context 'latestを渡すとき' do
        subject { Pbmenv.use("latest") }

        before do
          Pbmenv.use("0.1.5")
        end

        it '最後のバージョンでcurrentにシムリンクが貼っている' do
          subject
          expect(File.readlink("/usr/share/pbm/current")).to eq("/usr/share/pbm/v0.1.6")
        end
      end
    end
  end

  describe '.install, .uninstall' do
    context 'プレフィックスにvが付いているとき', :with_decompress_procon_pbm_man do
      let(:decompress_procon_pbm_man_versions) { ["0.1.5"] }
      let(:target_version) { decompress_procon_pbm_man_versions.first }

      subject { Pbmenv.install("v0.1.5") }

      include_examples "correct_pbm_dir_spec"
    end

    context '0.1.6, 0.1.5の順番でインストールするとき', :with_decompress_procon_pbm_man do
      let(:decompress_procon_pbm_man_versions) { ["0.1.6", "0.1.5", "0.1.20.1"] }

      subject do
        Pbmenv.install("0.1.6")
        Pbmenv.use("0.1.6")
        Pbmenv.install("0.1.5")
      end

      it 'currentに0.1.6のシムリンクは貼らない' do
        subject
        expect(File.readlink("/usr/share/pbm/current")).to eq("/usr/share/pbm/v0.1.6")
      end

      # すでに別のバージョンが入っていないとuseが実行されるので、別のバージョンが入っている必要がある
      context '0.1.20.1をインストールするとき with use_option' do
        subject { Pbmenv.install("0.1.20.1", use_option: true) }

        it 'currentに0.1.20.1のシムリンクは貼る' do
          subject
          expect(File.readlink("/usr/share/pbm/current")).to eq("/usr/share/pbm/v0.1.20.1")
        end
      end
    end

    context '0.1.6をインストールするとき', :with_decompress_procon_pbm_man do
      let(:decompress_procon_pbm_man_versions) { ["0.1.6"] }
      let(:target_version) { decompress_procon_pbm_man_versions.first }

      subject { Pbmenv.install(target_version) }

      it_behaves_like "correct_pbm_dir_spec"
    end

    context '0.1.20.1をインストールするとき', :with_decompress_procon_pbm_man do
      let(:decompress_procon_pbm_man_versions) { ["0.1.20.1"] }
      let(:target_version) { decompress_procon_pbm_man_versions.first }

      subject { Pbmenv.install(target_version, enable_pbm_cloud: true) }

      include_examples "correct_pbm_dir_spec"

      it "URLの行がアンコメントアウトされていること" do
        subject
        target_version = decompress_procon_pbm_man_versions.first
        a_pbm_path = "/usr/share/pbm/v#{target_version}"
        expect(File.read("#{a_pbm_path}/app.rb")).to match(%r!^  config.api_servers = 'https://pbm-cloud.herokuapp.com'$!)
      end
    end

    context '0.2.2をインストールするとき', :with_decompress_procon_pbm_man do
      let(:decompress_procon_pbm_man_versions) { ["0.2.2"] }
      let(:target_version) { decompress_procon_pbm_man_versions.first }

      context 'enable_pbm_cloud: true' do
        subject { Pbmenv.install(target_version, enable_pbm_cloud: true) }

        include_examples "correct_pbm_dir_spec"

        it "URLの行がアンコメントアウトされていること" do
          subject
          a_pbm_path = "/usr/share/pbm/v#{target_version}"
          expect(File.exists?("#{a_pbm_path}/app.rb.erb")).to eq(false)
          # 特定行をアンコメントしていること
          expect(File.read("#{a_pbm_path}/app.rb")).to match(%r!^  config.api_servers = \['https://pbm-cloud.herokuapp.com'\]$!)
        end
      end

      context 'enable_pbm_cloud: false' do
        subject { Pbmenv.install(target_version, enable_pbm_cloud: false) }

        include_examples "correct_pbm_dir_spec"

        it "URLの行がコメントアウトされていること" do
          subject
          a_pbm_path = "/usr/share/pbm/v#{target_version}"
          expect(File.exists?("#{a_pbm_path}/app.rb.erb")).to eq(false)
          # 特定行をコメントアウトしていること
          expect(File.read("#{a_pbm_path}/app.rb")).to match(%r!^  # config.api_servers = \['https://pbm-cloud.herokuapp.com'\]$!)
        end
      end
    end
  end
end
