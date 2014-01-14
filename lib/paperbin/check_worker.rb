class Paperbin::CheckWorker
  include Sidekiq::Worker

  def perform(item_id, item_type)
    paperbin_handler = Paperbin::Handler.new(item_id, item_type)
    paperbin_handler.check_versions
  end
end
