# app/admin/calendar.rb
ActiveAdmin.register_page "Log" do
  content do
    pre do
      File.readlines(Rails.root.join("log/#{Rails.env}.log")).split("\n") do |line|
        text_node line
      end
    end
  end
end
