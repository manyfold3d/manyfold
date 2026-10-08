shared_examples "CSRF protected" do |object_class|
  # Forgery protection is disabled in the test environment (config/environments/test.rb),
  # so these examples turn it back on to check that it actually protects the app.
  context "with forgery protection enabled" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:symbol) { object_class.to_s.underscore.to_sym }
    let(:path) { symbol.to_s.pluralize }
    let(:user) { create(:admin) }
    let(:object) { create(symbol, owner: user) }

    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    before do
      sign_in user
    end

    it "rejects an update without an authenticity token" do
      patch "/#{path}/#{object.to_param}", params: {symbol => {name: "forged"}}
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects an update with an invalid authenticity token" do
      patch "/#{path}/#{object.to_param}", params: {symbol => {name: "forged"}, :authenticity_token => "invalid"}
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not change the record when the authenticity token is missing" do
      expect {
        patch "/#{path}/#{object.to_param}", params: {symbol => {name: "forged"}}
      }.not_to change { object.reload.name }
    end
  end
end
