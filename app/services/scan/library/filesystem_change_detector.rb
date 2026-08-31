# frozen_string_literal: true

require "set"

module Scan
  module Library
    # Discovers new/changed/missing files on disk for a library scan.
    # Extracted from Scan::Library::DetectFilesystemChangesJob.
    # INIT-016/SPEC-002: mtime-prune discover + optional path_prefixes scoping.
    class FilesystemChangeDetector
      DEFAULT_MAX_DEPTH = 6

      def initialize(status:)
        @status = status
      end

      def filenames_on_disk(library)
        if library.storage_service == "filesystem"
          stream_indexable_relative_paths(library).to_a
        else
          library.list_files(File.join("**", ApplicationJob.file_pattern))
        end
      end

      def known_filenames(library)
        # Use ::Model / ::ModelFile — nested `module Scan` would otherwise resolve
        # Model → Scan::Model (job namespace) and ModelFile → Scan::ModelFile.
        ::ModelFile.without_special
          .joins(:model)
          .where(models: {library_id: library.id})
          .pluck("models.path", "model_files.filename")
          .map { |model_path, filename| File.join(model_path, filename) }
      end

      def filter_out_common_subfolders(folders)
        matcher = /\/(#{ApplicationJob.common_subfolders.keys.join("|")})$/i
        folders.map { |f| f.gsub(matcher, "") }.uniq
      end

      def model_paths_from_file_paths(file_paths)
        folders = file_paths.map { |f| File.dirname(f) }.uniq
        folders = filter_out_common_subfolders(folders)
        folders.delete("/")
        folders.delete(".")
        folders.delete("./")
        folders.compact_blank
      end

      def filter_indexable_changes(paths)
        paths = paths.select { |f|
          SupportedMimeTypes.indexable_extensions.include?(File.extname(f).tr(".", "").downcase)
        }
        patterns = SupportedMimeTypes.model_extensions.map { |it| %r{images/[^/]*\.#{it}}i }
        paths.reject { |f| patterns.any? { |pat| f.match?(pat) } }
      end

      def folders_with_changes(library, path_prefixes: nil)
        @status[:step] = "jobs.scan.detect_filesystem_changes.building_filename_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_filename_list')

        if library.storage_service == "filesystem"
          return discover_new_model_dirs(library, path_prefixes: path_prefixes)
        end

        on_disk = filter_indexable_changes(filenames_on_disk(library)).to_set
        known = known_filenames(library).to_set
        new_files = (on_disk - known).to_a
        @status[:step] = "jobs.scan.detect_filesystem_changes.building_folder_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_folder_list')
        model_paths_from_file_paths(new_files)
      end

      def models_with_new_files(library, since: :auto)
        return [] unless library.storage_service == "filesystem"

        root = library.path
        return [] unless root.present? && File.directory?(root)

        @status[:step] = "jobs.scan.detect_filesystem_changes.checking_known_models"
        since = last_detect_at(library) if since == :auto
        changed_ids = []
        checked = 0
        skipped_fresh = 0

        ::Model.where(library_id: library.id).find_each do |model|
          abs = File.join(root, model.path)
          next unless File.directory?(abs)
          next if File.symlink?(abs)

          unless dir_touched_since?(abs, since)
            skipped_fresh += 1
            next
          end

          checked += 1
          on_disk = shallow_indexable_relative_names(abs)
          existing = model.model_files.without_special.pluck(:filename).to_set
          changed_ids << model.id if (on_disk - existing).any?
        end

        remember_detect_at!(library)
        Rails.logger.info(
          "[scan] library=#{library.id} models_with_new_files " \
          "checked=#{checked} skipped_fresh=#{skipped_fresh} changed=#{changed_ids.size} " \
          "since=#{since&.iso8601}"
        )
        changed_ids
      end

      def missing_file_model_paths(library)
        if library.storage_service == "filesystem"
          return missing_model_paths_from_known_files(library)
        end

        on_disk = filter_indexable_changes(filenames_on_disk(library)).to_set
        known = known_filenames(library).to_set
        missing_files = (known - on_disk).to_a
        model_paths_from_file_paths(missing_files)
      end

      # INIT-016/SPEC-002 D-7: normalize/reject prefixes that escape the library root.
      def sanitize_path_prefixes(library, path_prefixes)
        return [] if path_prefixes.nil?

        root = library.path
        return [] unless root.present? && File.directory?(root)

        root = File.expand_path(root)
        root_real = safe_realpath(root) || root
        accepted = []

        Array(path_prefixes).each do |raw|
          normalized = normalize_relative_prefix(raw)
          if normalized.nil?
            Rails.logger.warn(
              "[scan] library=#{library.id} rejected path_prefix=#{raw.inspect} reason=invalid_relative"
            )
            next
          end

          abs = File.expand_path(File.join(root, normalized))
          unless path_inside_root?(abs, root_real)
            Rails.logger.warn(
              "[scan] library=#{library.id} rejected path_prefix=#{normalized.inspect} reason=outside_root"
            )
            next
          end

          unless File.directory?(abs) && !File.symlink?(abs)
            Rails.logger.warn(
              "[scan] library=#{library.id} rejected path_prefix=#{normalized.inspect} reason=not_directory"
            )
            next
          end

          accepted << normalized
        end

        accepted.uniq
      end

      def last_detect_at(library)
        Rails.cache.read(detect_cache_key(library))
      end

      def remember_detect_at!(library)
        Rails.cache.write(detect_cache_key(library), Time.current, expires_in: 30.days)
      end

      private

      def max_depth
        Integer(ENV.fetch("SCAN_MAX_DEPTH", DEFAULT_MAX_DEPTH))
      rescue ArgumentError, TypeError
        DEFAULT_MAX_DEPTH
      end

      def indexable_ext_set
        @indexable_ext_set ||= SupportedMimeTypes.indexable_extensions.map(&:downcase).to_set
      end

      def model_ext_set
        @model_ext_set ||= SupportedMimeTypes.model_extensions.map(&:downcase).to_set
      end

      def common_dir_names
        @common_dir_names ||= ApplicationJob.common_subfolders.keys.map(&:downcase).to_set
      end

      def common_subfolder_matcher
        @common_subfolder_matcher ||= /\/(#{ApplicationJob.common_subfolders.keys.join("|")})$/i
      end

      def stream_indexable_relative_paths(library)
        return enum_for(:stream_indexable_relative_paths, library) unless block_given?

        root = library.path
        return unless root.present? && File.directory?(root)

        root = File.expand_path(root)
        root_real = safe_realpath(root) || root
        require "find"

        Find.find(root) do |abs|
          base = File.basename(abs)
          if File.directory?(abs)
            if base.start_with?(".") || base == "#recycle" || base == "@eaDir" || File.symlink?(abs)
              Find.prune
              next
            end
            next
          end
          next unless File.file?(abs)
          next if File.symlink?(abs) && !path_inside_root?(abs, root_real)

          unless path_inside_root?(abs, root_real)
            next
          end

          ext = File.extname(abs).delete(".").downcase
          next unless indexable_ext_set.include?(ext)

          rel = abs.delete_prefix(root).delete_prefix(File::SEPARATOR).tr("\\", "/")
          next if rel.blank?
          next if SiteSettings.ignored_file?(rel)

          if model_ext_set.include?(ext) && rel.match?(%r{images/[^/]+\.#{Regexp.escape(ext)}$}i)
            next
          end

          yield rel
        end
      end

      def discover_new_model_dirs(library, path_prefixes: nil)
        @status[:step] = "jobs.scan.detect_filesystem_changes.building_folder_list"
        root = library.path
        return [] unless root.present? && File.directory?(root)

        root = File.expand_path(root)
        root_real = safe_realpath(root) || root

        known_paths = ::Model.where(library_id: library.id).pluck(:path).to_set
        known_from_files = known_filenames(library).map { |f| File.dirname(f).sub(common_subfolder_matcher, "") }.to_set
        known = known_paths | known_from_files

        since = last_detect_at(library)
        sanitized = sanitize_path_prefixes(library, path_prefixes)

        # INIT-016/SPEC-005 SEC-001: caller asked for a scoped walk but nothing survived sanitize —
        # fail closed (empty list), never visit the library root. Do not remember_detect_at!.
        if !path_prefixes.nil? && sanitized.empty?
          Rails.logger.warn(
            "[scan] library=#{library.id} reason=empty_after_sanitize — aborting discover"
          )
          return []
        end

        scoped = sanitized.any?
        new_folders = []
        pruned = {count: 0}

        visit_roots =
          if scoped
            sanitized.map do |prefix|
              {
                abs: File.join(root, prefix),
                rel: prefix,
                depth: prefix.split(File::SEPARATOR).reject(&:empty?).size
              }
            end
          else
            [{abs: root, rel: "", depth: 0}]
          end

        visit_roots.each do |start|
          visit_for_new_models(
            abs: start[:abs],
            rel: start[:rel],
            depth: start[:depth],
            root_real: root_real,
            known: known,
            new_folders: new_folders,
            library_id: library.id,
            since: since,
            pruned: pruned
          )
        end

        remember_detect_at!(library)
        Rails.logger.info(
          "[scan] library=#{library.id} folder_scan_complete " \
          "new_folders=#{new_folders.size} max_depth=#{max_depth} " \
          "pruned_dirs=#{pruned[:count]} prefixes=#{sanitized.size} " \
          "scoped=#{scoped} since=#{since&.iso8601}"
        )
        new_folders
      end

      def visit_for_new_models(abs:, rel:, depth:, root_real:, known:, new_folders:, library_id:, since:, pruned:)
        return if depth > max_depth
        return unless File.directory?(abs)
        return if File.symlink?(abs)

        if rel.present? && known.include?(rel)
          return
        end

        if rel.present? && model_dir_has_indexable?(abs) && !known.include?(rel)
          new_folders << rel
        end

        return if depth == max_depth

        # INIT-016/SPEC-002 D-2: mtime-prune untouched Category trees when watermark present.
        if rel.present? && !dir_touched_since?(abs, since)
          pruned[:count] += 1
          return
        end

        safe_children(abs).each do |name|
          next if common_dir_names.include?(name.downcase)

          child_abs = File.join(abs, name)
          next unless File.directory?(child_abs)
          next if File.symlink?(child_abs)
          next unless path_inside_root?(child_abs, root_real)

          child_rel = rel.present? ? File.join(rel, name).tr("\\", "/") : name
          visit_for_new_models(
            abs: child_abs,
            rel: child_rel,
            depth: depth + 1,
            root_real: root_real,
            known: known,
            new_folders: new_folders,
            library_id: library_id,
            since: since,
            pruned: pruned
          )
        end

        if (new_folders.size % 50).zero? && new_folders.any?
          Rails.logger.info(
            "[scan] library=#{library_id} discovering depth=#{depth} new_folders=#{new_folders.size}"
          )
        end
      end

      # Lexical relative-path checks before filesystem resolve (D-7).
      def normalize_relative_prefix(raw)
        return nil if raw.nil?

        str = raw.to_s
        return nil if str.empty?
        return nil if str.match?(/[\x00-\x1f\x7f]/)
        return nil if str.start_with?("/", "\\")
        return nil if str.match?(/\A[A-Za-z]:[\\\/]/) # Windows absolute

        cleaned = str.tr("\\", "/").squeeze("/").delete_prefix("/").delete_suffix("/")
        return nil if cleaned.empty?

        parts = cleaned.split("/")
        return nil if parts.any? { |p| p == ".." || p == "." || p.empty? }

        parts.join("/")
      end

      def safe_children(dir)
        Dir.children(dir).reject { |n| n.start_with?(".") || n == "#recycle" || n == "@eaDir" }
      rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
        []
      end

      def safe_realpath(path)
        File.realpath(path)
      rescue Errno::ENOENT, Errno::EACCES, Errno::EIO, Errno::ELOOP
        nil
      end

      def path_inside_root?(abs, root_real)
        real = safe_realpath(abs)
        return false if real.nil?

        real == root_real || real.start_with?(root_real + File::SEPARATOR)
      end

      def shallow_indexable_relative_names(abs_dir)
        names = []
        safe_children(abs_dir).each do |name|
          path = File.join(abs_dir, name)
          if File.file?(path) && !File.symlink?(path)
            ext = File.extname(name).delete(".").downcase
            names << name if indexable_ext_set.include?(ext)
          elsif File.directory?(path) && !File.symlink?(path) && common_dir_names.include?(name.downcase)
            safe_children(path).each do |fname|
              fpath = File.join(path, fname)
              next unless File.file?(fpath) && !File.symlink?(fpath)

              ext = File.extname(fname).delete(".").downcase
              names << File.join(name, fname) if indexable_ext_set.include?(ext)
            end
          end
        end
        names.to_set
      rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
        Set.new
      end

      def model_dir_has_indexable?(abs_dir)
        return false unless File.directory?(abs_dir)
        return false if File.symlink?(abs_dir)

        shallow_indexable_relative_names(abs_dir).any?
      end

      def missing_model_paths_from_known_files(library)
        root = library.path
        return [] unless root.present?

        missing = []
        known_filenames(library).each do |rel|
          abs = File.join(root, rel)
          missing << rel unless File.file?(abs)
        end
        model_paths_from_file_paths(missing)
      end

      def detect_cache_key(library)
        "manyfold:scan:library:#{library.id}:last_filesystem_detect_at"
      end

      def dir_touched_since?(abs_dir, since)
        return true if since.nil?

        # Compare at second precision — many filesystems store mtime without subseconds,
        # so a just-written watermark can otherwise false-prune freshly created dirs.
        since_i = since.to_i

        begin
          return true if File.mtime(abs_dir).to_i >= since_i
        rescue Errno::ENOENT, Errno::EACCES, Errno::EIO
          return true
        end

        safe_children(abs_dir).any? do |name|
          next false unless common_dir_names.include?(name.downcase)

          path = File.join(abs_dir, name)
          next false unless File.directory?(path) && !File.symlink?(path)

          File.mtime(path).to_i >= since_i
        rescue Errno::ENOENT, Errno::EACCES, Errno::EIO
          false
        end
      end
    end
  end
end
