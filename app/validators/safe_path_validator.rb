class SafePathValidator < ActiveModel::EachValidator
  UNSAFE = [
    "/bin",
    "/boot",
    "/dev",
    "/etc",
    "/lib",
    "/lost",
    "/proc",
    "/root",
    "/run",
    "/sbin",
    "/selinux",
    "/srv",
    "/usr"
  ]

  def validate_each(record, attribute, value)
    record.errors.add attribute, :unsafe if value === "/" || UNSAFE.any? { |x| value&.starts_with?(x) }
  end
end
