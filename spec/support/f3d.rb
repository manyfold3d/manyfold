RSpec.configure do |config|
  config.before do
    allow(F3d).to receive(:readers).and_return([
      "3MF           assimp     3D Manufacturing Format                    3mf       model/3mf",
      "OBJ           native     Wavefront OBJ                              obj       model/obj",
      "STL           native     Standard Triangle Language                 stl       model/stl"
    ])
  end
end
