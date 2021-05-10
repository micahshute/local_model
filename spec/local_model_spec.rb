RSpec.describe LocalModel do
  it "has a version number" do
    expect(LocalModel::VERSION).not_to be nil
  end

  describe ".config" do

    it "properly sets the configuration path" do
      path = "./"
      LocalModel.config do |c|
        c.path = path
      end

      expect(LocalModel.path).to eq path
    end
  end
end
