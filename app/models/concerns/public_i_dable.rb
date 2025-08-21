module PublicIDable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_public_id
    validates :public_id, presence: true, uniqueness: true, if: -> { respond_to? :public_id }

    def self.find_param(param)
      find_by!(public_id: param)
    end
  end

  def to_param
    public_id
  end

  ALPHABET = "bcdfghjklmnpqrstvwxz0123456789"
  private_constant :ALPHABET

  private

  def generate_public_id
    return if !respond_to?(:public_id) || public_id.present?
    self.public_id = begin
      Nanoid.generate(size: 12, alphabet: ALPHABET)
    end while public_id.nil? || self.class.exists?(public_id: public_id)
  end
end
