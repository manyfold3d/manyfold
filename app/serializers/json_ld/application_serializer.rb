module JsonLd
  class ApplicationSerializer
    def initialize(object)
      @object = object
    end

    def license(id)
      return if id.blank?
      {
        "@id": id.starts_with?("LicenseRef-") ?
          nil :
          "http://spdx.org/licenses/#{id}",
        licenseId: id
      }.compact
    end
  end
end
