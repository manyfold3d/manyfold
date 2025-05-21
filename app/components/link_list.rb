# frozen_string_literal: true

class Components::LinkList < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(links:)
    @links = links
  end

  def view_template
    return if @links.empty?
    ul class: "links" do
      @links.each do |link|
        if link.valid?
          li do
            link_to t("sites.%{site}" % {site: link.site}, default: "%{site}" % {site: link.site}), link.url
          end
        end
      end
    end
  end
end
