require "spec_helper"

describe Paperbin::Handler do

  let(:item) { double(organisation_id: "org1") }
  let(:target_id) { '123456789' }
  let(:target_type) { 'Client' }

  let!(:handler) { Paperbin::Handler.new target_id, target_type }
  before(:each) do
    Paperbin::Config.default_options[:path] = '/path'
    Paperbin::Config.default_options[:base_scope] = 'organisation_id'
    handler.stub(item: item)
  end

  it "return correct formatted_id" do
    handler.formatted_id.should == "000123456789"
  end

  it "split formatted_id into 3 sections" do
    handler.split_id.should == ['0001', '2345', '6789']
  end

  it 'return options' do
    handler.options.should == {path: '/path', base_scope: 'organisation_id'}
  end

  it "return directory" do
    handler.directory_path.should == "/path/org1/Client/0001/2345/6789"
  end

  context 'directories' do

    it 'generate directory when no exists' do
      Dir.stub(exists?: false)
      FileUtils.should_receive(:mkdir_p)
      handler.create_directory
    end

    it 'dont generate directory when exists' do
      Dir.stub(exists?: true)
      FileUtils.should_not_receive(:mkdir_p)
      handler.create_directory
    end

  end

  context 'generate_files' do
    let(:version_1) { double(id: 1, to_json: "json") }
    let(:version_2) { double(id: 2, to_json: "json") }
    let(:file) { double(write: true) }

    before do
      handler.stub(versions: [version_1, version_2])
      File.stub(open: file)
    end

    it 'create correct Gzip files' do
      Zlib::GzipWriter.should_receive(:open).twice
      handler.generate_files
    end

  end

  describe '#check_versions' do
    let(:version1) { double(id: 1, to_json: "json", delete: true) }
    let(:version2) { double(id: 2, to_json: "json", delete: true) }
    let(:file) { double(write: true) }

    before do
      handler.stub versions: [version1, version2]
      handler.stub files_exist?: true
      File.stub rename: true, delete: true
      Paperbin::WriteWorker.stub perform_async: true
    end

    subject(:check_versions) { handler.check_versions }

    context 'when md5 is valid' do
      before { handler.stub md5_valid?: true }

      it 'deletes the versions, except for the last one' do
        expect(version1).to receive(:delete).once
        expect(version2).to receive(:delete).never
        check_versions
      end

      it 'renames the file' do
        expect(File).to receive(:rename).twice
        check_versions
      end
    end

    context 'when md5 is invalid' do
      before { handler.stub md5_valid?: false }

      it 'removes the files' do
        expect(File).to receive(:delete).twice
        check_versions
      end

      it 'lodges a write worker to re-write the files' do
        expect(Paperbin::WriteWorker).to receive(:perform_async).once
          .with(target_id, target_type)
        check_versions
      end
    end

  end

end
