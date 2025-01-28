module ActivityPub
  class ApplicationSerializer < BaseSerializer
    def federate?
      @object.public?
    end

    def to
      PUBLIC_COLLECTION if @object.public?
    end
  end
end
