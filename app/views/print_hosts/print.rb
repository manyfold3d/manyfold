module Views::PrintHosts
  class Print < Views::Base
    include Phlex::Rails::Helpers::TurboFrameTag

    def initialize(print_host:, file:)
      @print_host = print_host
      @file = file
    end

    def view_template
      turbo_frame_tag "print-options" do
        h3 { "Print #{@file.name}" }
        p { "Printer: #{@print_host.name}" }
        p { "Turbo is working!" }
      end
    end
  end
end
