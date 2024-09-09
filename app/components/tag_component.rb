# frozen_string_literal: true

class TagComponent < ViewComponent::Base
  CLASSES = "badge rounded-pill bg-secondary tag"

  def initialize(tag:, show_count: false, filters: {}, html_options: {})
    @tag = tag
    @show_count = show_count
    @filters = filters || {}
    @filters[:tag] ||= []
    @html_options = html_options.merge({class: CLASSES})
  end

  erb_template <<-ERB
    <%= link_to @filters.merge(tag: @filters[:tag] | [@tag.name]), @html_options do %>
      <%= @tag.name %>
      <%- if @show_count %>
        (<%= @tag.taggings_count %>)
      <% end %>
    <% end %>
  ERB
end
