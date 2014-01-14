require "spec_helper"

describe PaperbinHandler do

  let(:item) { double(organisation_id: "org1") }

  subject { PaperbinHandler.new("123456789", "client") }
  before(:each) do
    Rails.stub_chain(:application, :config, :paperbin).and_return(
      {
        path: '/path',
        base_scope: 'organisation_id'
      })
    subject.stub(item: item)
  end

  it "return correct formatted_id" do
    subject.formatted_id.should == "000123456789"
  end

  it "split formatted_id into 3 sections" do
    subject.split_id.should == ['0001', '2345', '6789']
  end

  it 'return options', focus: true do
    subject.options.should == {path: '/path', base_scope: 'organisation_id'}
  end

  it "return directory" do
    subject.directory_path.should == "/path/org1/client/0001/2345/6789"
  end

  context 'directories' do

    it 'generate directory when no exists' do
      Dir.stub(exists?: false)
      FileUtils.should_receive(:mkdir_p)
      subject.create_directory
    end

    it 'dont generate directory when exists' do
      Dir.stub(exists?: true)
      FileUtils.should_not_receive(:mkdir_p)
      subject.create_directory
    end

  end

  context 'generate_files' do

    let(:version_1) { double(id: 1, to_json: "json") }
    let(:version_2) { double(id: 2, to_json: "json") }
    let(:file) { double(write: true) }

    before do
      subject.stub(versions: [version_1, version_2])
      File.stub(open: file)
    end

    it 'create correct Gzip files' do
      Zlib::GzipWriter.should_receive(:open).twice
      subject.generate_files
    end

  end

  context 'checker' do
    context '' do
    end
  end

end

