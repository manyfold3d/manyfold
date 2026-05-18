class FileHandlers::PrusaSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.prusa_slicer')

  class << self
    def input_types
      # PrusaSlicer only loads from printables.com, so this list is
      # empty until https://github.com/prusa3d/PrusaSlicer/issues/13752 is dealt with.
      []
    end

    def scheme
      "prusaslicer"
    end
  end
end
