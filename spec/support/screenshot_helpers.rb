# frozen_string_literal: true

module ScreenshotHelpers
  module Constants # rubocop:disable Metrics/ModuleLength
    COLOR = "#ef2929"
    DOTS_STYLE = <<~CSS.squish
      .documentation-dot {
          position: absolute;
          z-index: 1000;
          display: block;
          width: 1.5rem;
          height: 1.5rem;
          background-color: #{COLOR};
          content: '';
      }

      .documentation-dot--top {
          border-radius: 0.75rem 0.75rem 0.1rem 0.75rem;
          transform: translateX(-50%) translateY(-100%) rotate(45deg);
      }

      .documentation-dot--right {
          border-radius: 0.75rem 0.75rem 0.75rem 0.1rem;
          transform: translateX(0%) translateY(-50%) rotate(45deg);
      }

      .documentation-dot--bottom {
          border-radius: 0.1rem 0.75rem 0.75rem 0.75rem;
          transform: translateX(-50%) rotate(45deg);
      }

      .documentation-dot--left {
          border-radius: 0.75rem 0.1rem 0.75rem 0.75rem;
          transform: translateX(-100%) translateY(-50%) rotate(45deg);
      }

      .documentation-dot__counter {
        background-color: white;
        border-radius: 0.75rem;
        border: 2px solid #{COLOR};
        color: #{COLOR};
        font-family: monospace;
        font-size: 0.8rem;
        height: 1.5rem;
        line-height: 0.8rem;
        padding: 0.3rem 0;
        text-align: center;
        transform: rotate(-45deg);
        width: 1.5rem;
      }
    CSS

    CIRCLES_STYLE = <<~CSS.squish
      .documentation-circle{
        position: absolute;
        z-index: 1000;
        display: block;
        width: 2rem;
        height: 2rem;
        padding: 0.3rem 0;
        border: 2px solid #{COLOR};
        border-radius: 1rem;
        transform: translateX(-50%) translateY(-50%);
      }
    CSS

    OUTLINES_STYLE = <<~CSS.squish
      .documentation-outline{
        position: absolute;
        z-index: 1000;
        display: block;
        border: 2px solid #{COLOR};
      }
    CSS

    BOX_SHADOW = "0 0 0 2px #{COLOR}".freeze

    COMMON_JAVASCRIPT = <<~JS.squish
      if(!window.test_getElementPosition) {
        window.test_getElementPosition = function(element) {
          var width = element.offsetWidth;
          var height = element.offsetHeight;
          var top = 0, left = 0;
          do {
            top += element.offsetTop  || 0;
            left += element.offsetLeft || 0;
            element = element.offsetParent;
          } while(element);

          return {top: top,left: left, width: width, height: height};
        };
      }
    JS

    DOTS_JAVASCRIPT = <<~JS.squish
      if(!window.test_addDot){
        window.test_addDot = function(target, {counter = 1, offsetX = null, offsetY = null, position= 'top'}){
          var elementPosition = test_getElementPosition(target);
          elementPosition.bottom = elementPosition.top + elementPosition.height;
          elementPosition.right = elementPosition.left + elementPosition.width;

          console.log(position, elementPosition);

          var element = document.createElement('div');
          var counterElement = document.createElement('div');
          counterElement.innerHTML = counter;
          element.appendChild(counterElement);

          counterElement.classList.add("documentation-dot__counter");
          element.classList.add("documentation-dot");
          element.classList.add("documentation-dot--" + position);

          var transform = [];
          if(offsetX) transform.push('translateX('+offsetX+')');
          if(offsetY) transform.push('translateY('+offsetY+')');
          element.style.transform = transform.join(' ');

          if(position === 'top' || position === 'bottom'){
            element.style.top = elementPosition[position] + 'px';
            element.style.left = (elementPosition.left + elementPosition.width / 2) + 'px';
          }

          if(position === 'left' || position === 'right'){
            element.style.left = elementPosition[position] + 'px';
            element.style.top = (elementPosition.top + elementPosition.height / 2) + 'px';
          }
          document.body.appendChild(element);
        };

        var style = document.createElement('style');
        style.innerHTML = "#{DOTS_STYLE}";
        document.body.appendChild(style);
      }
    JS

    CIRCLES_JAVASCRIPT = <<~JS.squish
      if(!window.test_addCircle) {
        window.test_addCircle = function(target){
          var position = test_getElementPosition(target);
          var element = document.createElement('div');

          element.classList.add("documentation-circle");

          element.style.top = position.top + (position.height/2) + 'px';
          element.style.left = position.left + (position.width/2) + 'px';
          document.body.appendChild(element);
        };

        var style = document.createElement('style');
        style.innerHTML = "#{CIRCLES_STYLE}";
        document.body.appendChild(style);
      }
    JS

    OUTLINES_JAVASCRIPT = <<~JS.squish
      if(!window.test_addOutline) {
        window.test_addOutline = function(target){
          var position = test_getElementPosition(target);
          var element = document.createElement('div');
          element.classList.add("documentation-outline");
          element.style.top = position.top - 2 + 'px';
          element.style.left = position.left - 2 + 'px';
          element.style.width = position.width + 4 + 'px';
          element.style.height = position.height + 4 + 'px';
          document.body.appendChild(element);
        };

        var style = document.createElement('style');
        style.innerHTML = "#{OUTLINES_STYLE}";
        document.body.appendChild(style);
      }
    JS

    BOX_SHADOW_JAVASCRIPT = <<~JS.squish
      if(!window.test_addBoxShadow) {
        window.test_boxShadows = [];
        window.test_addBoxShadow = function(target) {
          var boxShadow = target.style.boxShadow;
          window.test_boxShadows.push({element: target, boxShadow: boxShadow});
          if (boxShadow.length > 0) target.style.boxShadow += "#{BOX_SHADOW}";
          else target.style.boxShadow = "#{BOX_SHADOW}";
        };
      }
    JS
  end

  def inject_dots(nodes = [], counter: 1, offset_x: nil, offset_y: nil, position: :top) # rubocop:disable Metrics/MethodLength
    execute_script Constants::COMMON_JAVASCRIPT
    execute_script Constants::DOTS_JAVASCRIPT

    nodes.each do |node|
      node = find(node) if node.is_a? String
      node.execute_script <<~JS.squish
        test_addDot(this, { counter: #{counter},
                            offsetX: #{offset_x ? "'#{offset_x}'" : "null"},
                            offsetX: #{offset_y ? "'#{offset_y}'" : "null"},
                            position: '#{position}'
        });
      JS
      counter += 1
    end
  end

  def inject_circles(nodes = [])
    execute_script Constants::COMMON_JAVASCRIPT
    execute_script Constants::CIRCLES_JAVASCRIPT

    nodes.each do |node|
      node = find(node) if node.is_a? String
      node.execute_script "test_addCircle(this)"
    end
  end

  # Adds a box around the nodes, with a small margin
  def inject_outlines(nodes = [])
    execute_script Constants::COMMON_JAVASCRIPT
    execute_script Constants::OUTLINES_JAVASCRIPT

    nodes.each do |node|
      node = find(node) if node.is_a? String
      node.execute_script "test_addOutline(this)"
    end
  end

  def inject_outlined_dots(nodes = [], counter: 1, style: :rectangle)
    case style
    when :rectangle
      inject_outlines nodes
    else
      outline_elements nodes
    end

    inject_dots nodes, counter: counter
  end

  # Adds a box shadow outlining the nodes. It will be really close to the nodes,
  # following their shapes.
  def outline_elements(nodes = [])
    execute_script Constants::COMMON_JAVASCRIPT
    execute_script Constants::BOX_SHADOW_JAVASCRIPT

    nodes.each do |node|
      node = find(node) if node.is_a? String
      node.execute_script "test_addBoxShadow(this)"
    end
  end

  def remove_injected_elements
    execute_script Constants::COMMON_JAVASCRIPT
    execute_script <<~JS.squish
      document.querySelectorAll('.documentation-dot').forEach(function(element){element.remove()});
      document.querySelectorAll('.documentation-circle').forEach(function(element){element.remove()});
      document.querySelectorAll('.documentation-outline').forEach(function(element){element.remove()});
      if (window.test_boxShadows) {
        window.test_boxShadows.forEach(function (node) {node.element.style.boxShadow = node.boxShadow});
        window.test_boxShadows = [];
      }
    JS
  end

  def take_and_crop_screenshot(name, top: 0, left: 0, width: nil, height: nil)
    name += "_#{I18n.locale}"

    paths = screenshot_and_save_page prefix: name, html: false
    path = File.join(Capybara::Screenshot.capybara_tmp_path, "#{name}.png")
    FileUtils.mv paths[:image], path

    processed = ImageProcessing::MiniMagick.source(path).crop!(left, top, width, height)
    FileUtils.mv processed, path
  end

  def reload_page
    execute_script "window.location.reload()"
  end

  def resize_window(width: nil, height: nil)
    size = Capybara.page.driver.browser.manage.window.size
    width ||= size.width
    height ||= size.height
    Capybara.page.driver.browser.manage.window.resize_to(width, height)
  end
end
