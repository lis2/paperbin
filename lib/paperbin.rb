require 'rails'
require 'sidekiq/worker'
require 'paperbin/version'
require 'paperbin_handler'
require 'paperbin_check_worker'
require 'paperbin_write_worker'
require 'models/version'

module Paperbin
  class Railtie < Rails::Railtie
    config.after_initialize do
      Version.send(:include, VersionWorkerMixin)
    end
  end
end



