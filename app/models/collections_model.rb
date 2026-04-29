# Many-to-many join table/model for Collections and Models
class CollectionsModel < ApplicationRecord
  belongs_to :collection, counter_cache: :models_count
  belongs_to :model
end
