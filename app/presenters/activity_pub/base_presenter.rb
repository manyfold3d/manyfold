module ActivityPub
  class BasePresenter
    PUBLIC_COLLECTION = "https://www.w3.org/ns/activitystreams#Public"

    def initialize(object)
      @object = object
    end

    def present!
      raise NotImplementedError
    end

    def federate?
      true
    end

    def to
      nil
    end

    def bto
      nil
    end

    def cc
      nil
    end

    def bcc
      nil
    end

    def audience
      nil
    end

    protected

    def address_fields
      {
        "to" => to,
        "bto" => bto,
        "cc" => cc,
        "bcc" => bcc,
        "audience" => audience
      }.compact
    end
  end
end
