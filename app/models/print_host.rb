class PrintHost < ApplicationRecord

  PROTOCOLS = [
    "moonraker"
  ].freeze

  validates :name, presence: true
  validates :endpoint, presence: true
  validates :protocol, presence: true, inclusion: {in: PROTOCOLS}
end
