class Paperbin::Handler < Struct.new(:id, :type)

  require 'zlib'
  require 'tempfile'

  def formatted_id
    "%012d" % id
  end

  def split_id
    formatted_id.scan(/.{4}/)
  end

  def current_path
  end

  def options
    Rails.application.config.paperbin || {}
  end

  def item
    scope = type.constantize
    scope = scope.with_deleted if scope.respond_to?(:with_deleted)
    scope.where(id: id).first
  end

  def directory_path
    dirs = []
    dirs << options[:path]
    dirs << item.send(options[:base_scope])
    dirs << type
    dirs += split_id
    File.join(dirs.map(&:to_s))
  end

  def versions
    Version.where(item_type: type, item_id: id)
  end

  def save_versions
    return true unless item
    create_directory
    generate_files
    Paperbin::CheckWorker.perform_async(id, type)
  end

  def create_directory
    FileUtils.mkdir_p(directory_path) unless Dir.exists?(directory_path)
  end

  def md5_file(version)
    File.join(directory_path, "#{version.id}.md5")
  end

  def gz_file(version, checked = false)
    File.join(directory_path, "#{version.id}.gz#{checked ? '' : '.unchecked'}")
  end

  def files_exist?(*args)
    Array(args).map{|file| File.exist?(file)}.all?
  end

  def md5_valid?(version)
    record_md5 = File.read(md5_file(version))
    data = Zlib::GzipReader.open(gz_file(version)) {|gz| gz.read }
    check_md5 = Digest::MD5.hexdigest(data)
    record_md5 == check_md5
  end

  def process_valid_records(version, last_item)
    # remove records from db expcet the lastest one
    version.delete unless version == last_item
    # rename file extension
    File.rename(gz_file(version), gz_file(version, true))

    Paperbin.send(options[:callback], gz_file(version, true)) if options[:callback]
  end

  def generate_files
    versions.each do |version|
      data = version.to_json
      unless files_exist?(gz_file(version))
        Zlib::GzipWriter.open(gz_file(version)) do |gz|
          gz.write data
        end
      end

      File.open(md5_file(version), "w") do |file|
        file.write(Digest::MD5.hexdigest(data))
      end

    end
  end

  def check_versions
    valid = true
    versions.each_with_index do |version, index|
      # check both file exist or not
      next unless files_exist?(md5_file(version), gz_file(version))

      if md5_valid?(version)
        process_valid_records(version, versions.last)
      else
        valid = false
        # remove both files
        [gz_file(version), md5_file(version)].each do |f|
          File.delete(f)
        end
      end
    end

    # lodge worker unless valid
    Paperbin::WriteWorker.perform_async(version.item_id, version.item_type) unless valid

  end
end


