class PaperbinHandler < Struct.new(:id, :type)

  require 'zlib'
  require 'tempfile'

  def initilize(version)
    @version = version
  end

  def formatted_id
    "%012d" % id
  end

  def split_id
    formatted_id.scan /.{4}/
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
    File.join(dirs)
  end

  def versions
    Version.where(item_type: type, item_id: id)
  end

  def save_versions
    return true unless item
    create_directory
    generate_files
    PaperBinCheckWorker.perform_async(id, type)
  end

  def create_directory
    FileUtils.mkdir_p(directory_path) unless Dir.exists?(directory_path)
  end

  def md5_file(version)
    File.join(directory_path, "#{version.id}.md5")
  end

  def gz_file(version)
    File.join(directory_path, "#{version.id}.gz")
  end

  def generate_files
    versions.each do |version|
      data = version.to_json

      Zlib::GzipWriter.open(gz_file(version)) do |gz|
        gz.write data
      end

      File.open(md5_file(version), "w") do |file|
        file.write(Digest::MD5.hexdigest(data))
      end

    end
  end


  def check_versions
    valid = true
    versions.each do |version|
      # check both file exist or not

      record_md5 = File.read(md5_file(version))
      check_md5 = Digest::MD5.hexdigest(Zlib::GzipReader.read(gz_file(version)))

      if record_md5 == check_md5
        # remove records from db expcet the lastest one
        # rename file extension
      else
        valid = false
        # remove both files
      end
    end

    # lodge worker unless valid

  end
end


