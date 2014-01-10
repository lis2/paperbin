class PaperBinCheckWorker
  include Sidekiq::Worker

  def perform(item_id, item_type)
    paperbin_handler = PaperbinHandler.new(item_id, item_type)
    paperbin_handler.check_versions
  end
end
