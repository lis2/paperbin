require 'rails'
require 'sidekiq/worker'

module Paperbin
  class Railtie < Rails::Railtie
    config.after_initialize do
      Version.send(:include, VersionWorkerMixin)
    end
  end
end

require 'paperbin/version'
require 'paperbin/handler'
require 'paperbin/check_worker'
require 'paperbin/write_worker'
require 'paperbin/version_mixin'
