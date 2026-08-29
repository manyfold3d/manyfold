# frozen_string_literal: true

class ResinBottle < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.resin_bottle")

  belongs_to :print_host, optional: true
  has_many :print_vats, dependent: :nullify

  validates :brand, presence: true
  validates :remaining_ml, :capacity_ml, presence: true,
    numericality: {greater_than_or_equal_to: 0}
  validate :remaining_within_capacity

  private

  def remaining_within_capacity
    return if remaining_ml.blank? || capacity_ml.blank?
    return if remaining_ml <= capacity_ml

    errors.add(:remaining_ml, :less_than_or_equal_to, count: capacity_ml)
  end
end
