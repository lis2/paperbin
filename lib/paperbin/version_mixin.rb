require "active_support/concern"

module Paperbin::VersionMixin
  extend ActiveSupport::Concern

  included do
    after_create :perform_worker
  end

  def perform_worker
    Paperbin::WriteWorker.perform_async(item_id, item_type)
  rescue Exception => e
    Airbrake.notify_or_ignore(e) if Paperbin::Handler.new.options[:airbrake_enabled]
  end

end

