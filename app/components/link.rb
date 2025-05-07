# frozen_string_literal: true

class Components::Link < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(link:)
    @link = link
  end

  def view_template
    return unless @link.valid?
    li do
      link_to t("sites.%{site}" % {site: @link.site}, default: "%{site}" % {site: @link.site}), @link.url
    end
  end
end
