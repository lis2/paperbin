class Paperbin::Handler < Struct.new(:id, :type)
  require 'zlib'
  require 'tempfile'

  def formatted_id
    "%012d" % id
  end

  def split
    formatted_id.scan(/.{4}/)
  end

  def dir_split_id
    split[0...-1]
  end

  def archive_split_id
    split.last
  end

  def options
    Paperbin::Config.default_options
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
    dirs += dir_split_id
    File.join(dirs.map(&:to_s))
  end

  def old_directory_path
    File.join(directory_path, archive_split_id)
  end

  def archive_path
    File.join(directory_path, "#{archive_split_id}.zip")
  end

  def create_archive_file
    unless File.exists?(archive_path)
      Zippy.create archive_path do |z|
        z["created_at.txt"] = Date.today.to_s
        handle_old_files(z)
      end
    end
  end

  def handle_old_files(z)
    if File.directory?(old_directory_path)
      Dir.new(old_directory_path).each do |file|
        if file =~ /\.gz/
          name = file.split(".").first
          z["#{name}.json"] = Zlib::GzipReader.open(File.join(old_directory_path, file)) {|gz| gz.read }
        end
      end
      FileUtils.remove_dir(old_directory_path)
    end
  end

  def versions
    Version.where(item_type: type, item_id: id)
  end

  def save_versions
    return true unless item
    create_directory
    create_archive_file
    generate_files
    Paperbin::CheckWorker.perform_async(id, type)
  end

  def create_directory
    FileUtils.mkdir_p(directory_path) unless Dir.exists?(directory_path)
  end

  def md5_file(version)
    "#{version.id}.md5"
  end

  def md5_file_path(version)
    File.join(directory_path, "#{md5_file(version)}")
  end

  def json_file(version)
    "#{version.id}.json"
  end

  def json_file_path(version, checked = false)
    File.join(directory_path, "#{json_file(version)}#{checked ? '' : '.unchecked'}")
  end

  def files_exist?(*args)
    Array(args).map{|file| File.exist?(file)}.all?
  end

  def md5_valid?(version)
    record_md5 = File.read(md5_file_path(version))
    data = File.open(json_file_path(version), "r") { |f| f.read }
    check_md5 = Digest::MD5.hexdigest(data)
    record_md5 == check_md5
  end

  def process_valid_records(version, last_item)
    # remove records from db expcet the lastest one
    version.delete unless version == last_item
    # rename file extension
    File.rename(json_file_path(version), json_file_path(version, true))
    Zippy.open(archive_path) do |z|
      z["#{json_file(version).to_s}"] = File.open(json_file_path(version, true)) { |f| f.read }
    end
    File.delete(md5_file_path(version))
    File.delete(json_file_path(version, true))
    options[:callback].call(json_file_path(version, true)) if options[:callback]
  end

  def generate_files
    versions.each do |version|
      write_json_file version
      write_md5_file version
    end
  end

  def write_json_file(version)
    path = json_file_path version
    unless files_exist?(path)
      File.open(path, "w") { |f| f.write(string_data(version)) }
      timestamp = version.created_at.to_time
      File.utime timestamp, timestamp, path
    end
  end

  def write_md5_file(version)
    File.open(md5_file_path(version), "w") do |file|
      md5 = Digest::MD5.hexdigest(string_data(version))
      file.write md5
    end
  end

  def string_data(version)
    version.to_json
  end

  def check_versions
    versions.each_with_index do |version, index|
      # check both file exist or not
      next unless files_exist?(md5_file_path(version), json_file_path(version))

      if md5_valid?(version)
        process_valid_records(version, versions.last)
      else
        # remove both files
        [json_file_path(version), md5_file_path(version)].each do |f|
          File.delete(f)
        end
        raise Errno::ENOENT
      end
    end
  rescue Errno::ENOENT
    # lodge worker unless valid
    Paperbin::WriteWorker.perform_async(id, type)
  end
end


