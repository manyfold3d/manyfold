class LibraryScanJob < ApplicationJob
  queue_as :default

  def perform(library)
    # For each directory in the library, create a model
    Dir.open(library.path) do |dir|
      dir.each_child do |child|
        if Dir.exist?(File.join(dir.path, child))
          model = library.models.find_or_create_by(name: child.humanize.titleize, path: child)
          ModelScanJob.perform_later(model)
        end
      end
    end
  end
end
