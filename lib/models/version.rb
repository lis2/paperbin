require "active_support/concern"


module VersionWorkerMixin
  extend ActiveSupport::Concern

  included do
    after_create :perform_worker
  end

  def perform_worker
    PaperBinWriteWorker.perform_async(self.item_id, self.item_type)
  end

end

