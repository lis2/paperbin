require "active_support/concern"


module VersionWorkerMixin
  extend ActiveSupport::Concern

  included do
    after_create :perform_worker
  end

  def perform_worker
    PaperBinWriteWorker.perform_async(self.id)
  end

end

Version.extend(VersionWorkerMixin) if Module.const_defined?("Version")
