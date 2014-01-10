module  
  extend ActiveSupport::Concern

  included do
    after_create :perform_worker
  end

  def perform_worker
    PaperBinWriteWorker.perform_async(self.id)
  end

end 

class PaperBinWriteWorker
  include Sidekiq::Worker

  def perform(version_id)
    version = Version.find version_id
    return true unless version
    paperbin_writer = PaperbinWriter.new(version.item)
    paperbin_writer.save_version
  end
end
