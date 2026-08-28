# frozen_string_literal: true

# Phase 1 SDCP client stub — full WS/HTTP behavior is INIT-007/SPEC-003.
module Print
  class SdcpService
    # i18n-tasks-use t("print_hosts.protocols.sdcp")
    PROTOCOL = "sdcp".freeze

    # UniFormation GK3 Pro advertises CTB + JXS (RSCH-002 attributes).
    INPUT_TYPES = [Mime[:chitubox], Mime[:jxs]].freeze

    def initialize(print_host:)
      @print_host = print_host
    end

    def ok?
      false
    end
  end
end
