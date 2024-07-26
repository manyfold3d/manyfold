module Listable
  extend ActiveSupport::Concern

  included do
    acts_as_favoritable
  end
end
