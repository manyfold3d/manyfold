# frozen_string_literal: true

class LinkComponent < ViewComponent::Base
  def initialize(link:)
    @link = link
  end

  def call
    return unless @link.valid?
    content_tag :li do
      link_to t("sites.%{site}" % {site: @link.site}, default: "%{site}" % {site: @link.site}), @link.url
    end
  end
end
