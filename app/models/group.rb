class Group < ApplicationRecord
  include CaberSubject

  belongs_to :creator

  has_many :memberships, dependent: :destroy
  has_many :members, through: "memberships", source: :user
end
