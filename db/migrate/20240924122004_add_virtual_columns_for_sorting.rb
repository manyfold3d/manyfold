class AddVirtualColumnsForSorting < ActiveRecord::Migration[7.1]
  def change
    [:models, :creators, :collections].each do |table|
      add_column table, :name_lower, :virtual, type: :string, as: "LOWER(name)", stored: true
      add_index table, :name_lower
    end
  end
end
