class Paperbin::Config < Struct.new(:options)
  def self.default_options
    @default_options ||= {}
  end
end
