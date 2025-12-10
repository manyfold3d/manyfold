class Group < ApplicationRecord
  include CaberSubject

  belongs_to :creator
  validates :name, presence: true

  has_many :memberships, dependent: :destroy
  has_many :members, through: "memberships", source: :user

  accepts_nested_attributes_for :memberships, reject_if: :all_blank, allow_destroy: true
end
