module PublicIDable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_public_id
    validates :public_id, presence: true, uniqueness: true
  end

  def to_param
    public_id
  end

  private

  ALPHABET = "bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ0123456789"

  def generate_public_id
    self.public_id ||= Nanoid.generate(size: 8, alphabet: ALPHABET)
  end
end
