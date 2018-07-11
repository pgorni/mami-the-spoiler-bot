Rspec.describe "bot" do
  context "database" do
    it "expects the default database file to exist if MAMI_DB isn't set" do 
      expect(File.exist?('mami_server_configs.db')).to eq(true) unless ENV["MAMI_DB"]
    end
  end
end