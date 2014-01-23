class Paperbin::WriteWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['PAPERBIN_WRITE_QUEUE'] || 'default')

  def perform(item_id, item_type)
    paperbin_handler = Paperbin::Handler.new(item_id, item_type)
    paperbin_handler.save_versions
  end
end
