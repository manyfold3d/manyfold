# frozen_string_literal: true

module Print
  # Fail-closed compatibility check between a sliced-artifact stamp and a PrintHost
  # capability set (REQ-004). Reasons are machine-readable codes for UI / API.
  class CompatibilityGate
    Reason = Data.define(:code, :message, :expected, :actual)
    Result = Data.define(:pass?, :reasons) do
      def fail? = !pass?
    end

    # stamp keys (symbol or string):
    #   :format (required) — e.g. "ctb", "jxs"
    #   :resolution_w, :resolution_h — optional; checked when present
    #   :z_height_mm — optional; must be <= host build_z_mm when present
    #   :aa — optional anti-aliasing level; checked when present (fail-closed)
    # host_capabilities — optional overlay (e.g. { aa_max: 8 }) merged over print_host
    def self.call(print_host:, stamp:, host_capabilities: {})
      new(print_host:, stamp:, host_capabilities:).call
    end

    def initialize(print_host:, stamp:, host_capabilities: {})
      @print_host = print_host
      @stamp = stamp.to_h.transform_keys { |k| k.to_sym }
      @host_capabilities = host_capabilities.to_h.transform_keys { |k| k.to_sym }
    end

    def call
      reasons = []
      reasons.concat(check_format)
      reasons.concat(check_resolution)
      reasons.concat(check_z_height)
      reasons.concat(check_aa)
      Result.new(pass?: reasons.empty?, reasons: reasons)
    end

    private

    attr_reader :print_host, :stamp, :host_capabilities

    def check_format
      format = normalize_format(stamp[:format])
      if format.blank?
        return [reason(:format_missing, "Artifact format is required", expected: "non-blank format", actual: nil)]
      end

      allowed = print_host.capability_formats.map { |f| normalize_format(f) }
      return [] if allowed.include?(format)

      [reason(:format_unsupported, "Format not supported by printer", expected: allowed, actual: format)]
    end

    def check_resolution
      return [] unless stamp.key?(:resolution_w) || stamp.key?(:resolution_h)
      return [] if stamp[:resolution_w].nil? && stamp[:resolution_h].nil?

      host_w = capability(:resolution_w) || print_host.resolution_w
      host_h = capability(:resolution_h) || print_host.resolution_h
      if host_w.blank? || host_h.blank?
        return [reason(:resolution_host_unknown, "Printer resolution not configured",
          expected: "printer resolution_w/h", actual: stamp_resolution_label)]
      end

      stamp_w = stamp[:resolution_w].to_i
      stamp_h = stamp[:resolution_h].to_i
      return [] if stamp_w == host_w.to_i && stamp_h == host_h.to_i

      [reason(:resolution_mismatch, "Resolution does not match printer",
        expected: "#{host_w}×#{host_h}", actual: stamp_resolution_label)]
    end

    def check_z_height
      return [] unless stamp.key?(:z_height_mm)
      return [] if stamp[:z_height_mm].nil?

      host_z = capability(:build_z_mm) || print_host.build_z_mm
      if host_z.blank?
        return [reason(:z_host_unknown, "Printer build Z not configured",
          expected: "printer build_z_mm", actual: stamp[:z_height_mm])]
      end

      z = stamp[:z_height_mm].to_d
      return [] if z <= host_z.to_d

      [reason(:z_exceeds_build, "Z height exceeds printer build volume",
        expected: "<= #{host_z}", actual: z)]
    end

    def check_aa
      return [] unless stamp.key?(:aa)
      return [] if stamp[:aa].nil?

      aa = stamp[:aa]
      # aa 0 / false means no AA required
      return [] if aa == false || aa.to_i.zero?

      aa_max = capability(:aa_max)
      if aa_max.nil?
        return [reason(:aa_unsupported, "Anti-aliasing required but printer AA capability unknown",
          expected: "aa_max configured", actual: aa)]
      end

      return [] if aa.to_i <= aa_max.to_i

      [reason(:aa_exceeds_max, "Anti-aliasing level exceeds printer maximum",
        expected: "<= #{aa_max}", actual: aa)]
    end

    def capability(key)
      host_capabilities[key]
    end

    def normalize_format(value)
      value.to_s.strip.downcase.delete_prefix(".")
    end

    def stamp_resolution_label
      "#{stamp[:resolution_w]}×#{stamp[:resolution_h]}"
    end

    def reason(code, message, expected:, actual:)
      Reason.new(code: code, message: message, expected: expected, actual: actual)
    end
  end
end
