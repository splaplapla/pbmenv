# frozen_string_literal: true

require 'open-uri'
require 'json'

module Pbmenv
  class PBM
    def available_versions
      response = URI.open 'https://api.github.com/repos/splaplapla/procon_bypass_man/tags'
      JSON.parse(response.read)
    end

    def versions
      Dir.glob("#{Pbmenv::PBM_DIR}/v*")
    end
  end
end
