shared_examples "GenericSerializer" do
  it "includes version" do
    expect(output[:version]).to eq "1.0"
  end

  it "includes cache age" do
    expect(output[:cache_age]).to eq 86400
  end

  it "includes site name" do
    expect(output[:provider_name]).to eq "Manyfold"
  end

  it "includes site url" do
    expect(output[:provider_url]).to eq "http://localhost:3214/"
  end
end
