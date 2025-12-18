class Components::ColumnHeader < Components::Base
  include Phlex::Rails::Helpers::Request

  def initialize(label:, sort_param: nil, sort_option: nil, sort_default: false, sort_ascending: true)
    @label = label
    @sort_param_name = sort_param&.to_s
    @sort_option = sort_option&.to_s
    @sort_default = sort_default
    @sort_ascending = sort_ascending
  end

  def before_template
    if @sort_option
      @sort_param = request.params[@sort_param_name]
      @active_sort = @sort_param == @sort_option || (@sort_default && @sort_param.blank?)
      if @active_sort
        @aria_options = {
          sort: @sort_ascending ? "ascending" : "descending"
        }
      end
    end
  end

  def view_template
    th aria: @aria_options do
      if @sort_option
        if @active_sort
          span { @label }
          whitespace
          Icon(icon: "caret-down-fill", label: t("components.column_header.current_sort"))
        else
          a href: url_for(request.params.merge(@sort_param_name => @sort_option)), class: "link-body-emphasis link-underline link-underline-opacity-0", aria: {role: "button"} do
            span { @label }
            whitespace
            Icon(icon: "caret-down", label: t("components.column_header.sort_by"))
          end
        end
      else
        span { @label }
      end
    end
  end
end
