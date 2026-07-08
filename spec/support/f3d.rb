RSpec.configure do |config|
  config.before do
    allow(FileHandlers::F3dCli).to receive(:input_types).and_return([
      Mime[:threemf], Mime[:obj], Mime[:stl], Mime[:jpg]
    ])
  end
end
