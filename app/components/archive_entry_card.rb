# frozen_string_literal: true

class Components::ArchiveEntryCard < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::NumberToHumanSize

  def initialize(entry:, file:)
    @entry = entry
    @file = file
  end

  def view_template
    div(
      id: self.class.dom_id_for(@entry),
      class: "archive-entry-card rounded-lg border border-secondary-200 dark:border-secondary-700 overflow-hidden bg-surface dark:bg-secondary-900 min-w-0"
    ) do
      preview_slot
      div(class: "p-2 space-y-1") do
        p(
          class: "text-xs font-medium text-secondary-900 dark:text-secondary-100 truncate",
          title: @entry.pathname
        ) { @entry.pathname }
        meta_line
        actions
      end
    end
  end

  def self.dom_id_for(entry)
    "archive_entry_#{entry.to_param}"
  end

  private

  # 4:3 slot is PNG, loading, or failed — pathname stays a caption (INIT-003/SPEC-003).
  def preview_slot
    div(class: "archive-entry-preview-slot aspect-[4/3] bg-secondary-100 dark:bg-secondary-800 relative flex items-center justify-center overflow-hidden") do
      if @entry.preview_exists?
        ready_preview
      elsif preview_in_flight?
        loading_preview
      elsif preview_failed?
        failed_preview
      else
        kind_placeholder
      end
    end
  end

  def ready_preview
    image_tag preview_model_model_file_archive_entry_path(@file.model, @file, @entry),
      alt: @entry.name,
      class: "archive-entry-preview-image absolute inset-0 w-full h-full object-cover",
      loading: "lazy"
  end

  def loading_preview
    div(
      class: "archive-entry-preview-loading absolute inset-0 animate-pulse bg-secondary-200 dark:bg-secondary-700",
      role: "status",
      "aria-busy": "true"
    ) do
      span(class: "sr-only") { t("archive_entries.card.preview_loading") }
    end
  end

  def failed_preview
    div(
      class: "archive-entry-preview-failed flex items-center justify-center",
      role: "img",
      "aria-label": t("archive_entries.card.preview_failed")
    ) do
      i(class: "bi bi-exclamation-triangle text-3xl text-secondary-400", "aria-hidden": "true")
    end
  end

  def kind_placeholder
    if @entry.is_renderable?
      i(class: "bi bi-box-fill text-3xl text-secondary-400", "aria-hidden": "true")
    elsif @entry.is_image?
      i(class: "bi bi-image text-3xl text-secondary-400", "aria-hidden": "true")
    else
      i(class: "bi bi-file-earmark text-3xl text-secondary-400", "aria-hidden": "true")
    end
  end

  def preview_in_flight?
    previewable_entry? && @entry.status.in?(%w[listed preview_pending])
  end

  def preview_failed?
    previewable_entry? && @entry.status == "preview_failed"
  end

  def previewable_entry?
    @entry.is_renderable? || @entry.is_image?
  end

  def meta_line
    p(class: "text-[11px] text-secondary-500 dark:text-secondary-400") do
      span(class: "uppercase") { @entry.kind }
      if @entry.size
        plain " · "
        plain number_to_human_size(@entry.size, precision: 2)
      end
      plain " · "
      plain @entry.status.humanize
    end
  end

  def actions
    div(class: "flex flex-wrap gap-1 pt-1") do
      if @entry.is_renderable? || @entry.is_image?
        link_to t("archive_entries.panel.open"),
          model_model_file_archive_entry_path(@file.model, @file, @entry),
          class: "text-xs text-primary-700 dark:text-primary-400 no-underline hover:underline"
      end
      link_to t("archive_entries.panel.download"),
        download_model_model_file_archive_entry_path(@file.model, @file, @entry),
        class: "text-xs text-primary-700 dark:text-primary-400 no-underline hover:underline"
    end
  end
end
