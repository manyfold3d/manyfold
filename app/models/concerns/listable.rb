module Listable
  extend ActiveSupport::Concern

  included do
    acts_as_favoritable
  end

  def listers(list_name)
    favoritors(scope: list_name)
  end
end
