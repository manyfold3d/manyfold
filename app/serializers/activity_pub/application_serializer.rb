module ActivityPub
  class ApplicationSerializer < BaseSerializer
    def federate?
      @object.public?
    end

    def to
      PUBLIC_COLLECTION if @object.public?
    end

    protected

    def summary_html
      return unless @object.caption || @object.notes
      "<section>#{"<header>#{@object.caption}</header>" if @object.caption}#{Kramdown::Document.new(@object.notes).to_html.rstrip if @object.notes}</section>"
    end
  end
end
