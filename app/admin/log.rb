# app/admin/calendar.rb
ActiveAdmin.register_page "Log" do
  content do
    h2 "log/#{Rails.env}.log"
    div style: "padding: 0px 1em; background: #eee; border: 1px solid black; width: 90vw; overflow-x: scroll" do
      pre do
        Rails.root.join("log/#{Rails.env}.log").readlines.split("\n") do |line|
          text_node line
        end
      end
    end
  end
end
