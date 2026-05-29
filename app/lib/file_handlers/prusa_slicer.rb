class FileHandlers::PrusaSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.prusa_slicer')

  # PrusaSlicer only loads from printables.com, so this list is
  # empty until https://github.com/prusa3d/PrusaSlicer/issues/13752 is dealt with.
  INPUT_TYPES = [].freeze

  def self.scheme
    "prusaslicer"
  end
end
