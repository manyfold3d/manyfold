shared_examples "GenericOEmbedSerializer" do
  it "includes version" do
    expect(result[:version]).to eq "1.0"
  end

  it "includes cache age" do
    expect(result[:cache_age]).to eq 86400
  end

  it "includes site name" do
    expect(result[:provider_name]).to eq "Manyfold"
  end

  it "includes site url" do
    expect(result[:provider_url]).to eq "http://localhost:3214/"
  end
end
