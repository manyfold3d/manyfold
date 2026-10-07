class Thumbnailers::F3d
  F3D_OPTS = {
    "ambient-occlusion" => "1",
    "anti-aliasing" => "true",
    "axis" => "0",
    "background-color" => "0,0,0",
    "filename" => "0",
    "grid" => "1",
    "grid-color" => "0,255,255",
    "grid-subdivisions" => 0,
    "grid-unit" => "10",
    "no-config" => "1",
    "output" => "-",
    "resolution" => "512,512",
    "tone-mapping" => "1",
    "translucency-support" => "1"
  }.freeze

  CAMERA_OPTS = {
    "+z" => "-1,1,-0.5",
    "+y" => "-1,-0.5,-1"
  }

  def initialize(file:, record:)
    @file = file
    @record = record
  end

  def call
    up = @record.up_direction
    options = F3D_OPTS.merge(
      "up" => up,
      "camera-direction" => CAMERA_OPTS[up]
    )
    options["color"] = "1,1,1" if @record.mime_type.to_s == "model/obj"
    if (plane = @record.planar?)
      options["grid"] = "0"
      options["up"] = {
        x: "-x",
        y: "-y",
        z: "-z"
      }[plane]
      options["camera-direction"] = {
        x: "0,0,-1",
        y: "-1,0,0",
        z: "0,-1,0"
      }[plane]
    end
    output, _err = Open3.capture3("f3d", @file.path, *options.map { |k, v| "--#{k}=#{v}" })
    {
      render: (output.length > 0) ? StringIO.new(output) : nil
    }.compact
  end
end
