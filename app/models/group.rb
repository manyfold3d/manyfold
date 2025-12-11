class Group < ApplicationRecord
  include CaberSubject

  belongs_to :creator
  validates :name, presence: true

  has_many :memberships, dependent: :destroy
  has_many :members, through: "memberships", source: :user

  accepts_nested_attributes_for :memberships, reject_if: :all_blank, allow_destroy: true

  def typed_id
    "group::#{id}"
  end

  TYPED_ID_PATTERN = /group::([[:digit:]]+)/

  def self.find_by_typed_id(typed_id, scope: Group)
    typed_id.match(TYPED_ID_PATTERN)
    scope.find($1) if $1
  end
end
