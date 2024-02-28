# From https://mattbrictson.com/blog/easier-nested-layouts-in-rails

module LayoutsHelper
  def parent_layout(layout)
    @view_flow.set(:layout, output_buffer) # rubocop:todo Rails/HelperInstanceVariable
    output = render(template: "layouts/#{layout}")
    self.output_buffer = ActionView::OutputBuffer.new(output)
  end
end
