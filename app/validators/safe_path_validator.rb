class SafePathValidator < ActiveModel::EachValidator
  UNSAFE = [
    nil,
    "bin",
    "boot",
    "dev",
    "etc",
    "lib",
    "lost",
    "proc",
    "root",
    "run",
    "sbin",
    "selinux",
    "srv",
    "usr"
  ]

  def validate_each(record, attribute, value)
    return if value.nil?
    start = Pathname.new(value).each_filename.to_a.first
    # i18n-tasks-use t("activerecord.errors.models.library.attributes.path.unsafe")
    record.errors.add attribute, :unsafe if UNSAFE.any?(start)
  end
end
