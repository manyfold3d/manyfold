# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_08_29_153100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "altcha_solutions", force: :cascade do |t|
    t.string "algorithm"
    t.string "challenge"
    t.string "salt"
    t.string "signature"
    t.integer "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["algorithm", "challenge", "salt", "signature", "number"], name: "index_altcha_solutions", unique: true
  end

  create_table "archive_entries", force: :cascade do |t|
    t.bigint "model_file_id", null: false
    t.string "public_id", null: false
    t.string "pathname", null: false
    t.bigint "size"
    t.bigint "compressed_size"
    t.string "kind", default: "other", null: false
    t.string "preview_path"
    t.string "extracted_path"
    t.string "status", default: "listed", null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_file_id", "kind"], name: "index_archive_entries_on_model_file_id_and_kind"
    t.index ["model_file_id", "pathname"], name: "index_archive_entries_on_model_file_id_and_pathname", unique: true
    t.index ["model_file_id", "status"], name: "index_archive_entries_on_model_file_id_and_status"
    t.index ["model_file_id"], name: "index_archive_entries_on_model_file_id"
    t.index ["pathname"], name: "index_archive_entries_on_pathname_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["public_id"], name: "index_archive_entries_on_public_id", unique: true
  end

  create_table "caber_relations", force: :cascade do |t|
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "permission"
    t.string "object_type", null: false
    t.bigint "object_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["object_type", "object_id"], name: "index_caber_relations_on_object"
    t.index ["subject_id", "subject_type", "object_id", "object_type"], name: "idx_on_subject_id_subject_type_object_id_object_typ_a279b094be", unique: true
    t.index ["subject_type", "subject_id"], name: "index_caber_relations_on_subject"
  end

  create_table "collections", force: :cascade do |t|
    t.string "name"
    t.text "notes"
    t.text "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "collection_id"
    t.string "slug"
    t.string "public_id"
    t.virtual "name_lower", type: :string, as: "lower((name)::text)", stored: true
    t.bigint "creator_id"
    t.string "indexable"
    t.string "ai_indexable"
    t.index ["collection_id"], name: "index_collections_on_collection_id"
    t.index ["created_at"], name: "index_collections_on_created_at"
    t.index ["creator_id"], name: "index_collections_on_creator_id"
    t.index ["name"], name: "index_collections_on_name", unique: true
    t.index ["name_lower"], name: "index_collections_on_name_lower"
    t.index ["public_id"], name: "index_collections_on_public_id"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
    t.index ["updated_at"], name: "index_collections_on_updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.string "public_id", null: false
    t.string "commenter_type"
    t.bigint "commenter_id"
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system", default: false, null: false
    t.boolean "sensitive", default: false, null: false
    t.string "federated_url"
    t.bigint "federails_actor_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["commenter_type", "commenter_id"], name: "index_comments_on_commenter"
    t.index ["federails_actor_id"], name: "index_comments_on_federails_actor_id"
    t.index ["public_id"], name: "index_comments_on_public_id", unique: true
  end

  create_table "creators", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.text "caption"
    t.string "slug"
    t.string "public_id"
    t.virtual "name_lower", type: :string, as: "lower((name)::text)", stored: true
    t.string "indexable"
    t.string "ai_indexable"
    t.json "avatar_data"
    t.json "banner_data"
    t.index ["created_at"], name: "index_creators_on_created_at"
    t.index ["name"], name: "index_creators_on_name", unique: true
    t.index ["name_lower"], name: "index_creators_on_name_lower"
    t.index ["public_id"], name: "index_creators_on_public_id"
    t.index ["slug"], name: "index_creators_on_slug", unique: true
    t.index ["updated_at"], name: "index_creators_on_updated_at"
  end

  create_table "fasp_client_backfill_requests", force: :cascade do |t|
    t.bigint "fasp_client_provider_id", null: false
    t.string "category"
    t.integer "max_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fasp_client_provider_id"], name: "index_fasp_client_backfill_requests_on_fasp_client_provider_id"
  end

  create_table "fasp_client_event_subscriptions", force: :cascade do |t|
    t.bigint "fasp_client_provider_id", null: false
    t.string "category"
    t.string "subscription_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fasp_client_provider_id"], name: "idx_on_fasp_client_provider_id_dd4cdc071c"
  end

  create_table "fasp_client_providers", force: :cascade do |t|
    t.string "uuid"
    t.string "name"
    t.string "base_url"
    t.string "server_id"
    t.string "public_key"
    t.string "ed25519_signing_key"
    t.integer "status"
    t.json "capabilities"
    t.json "privacy_policy"
    t.string "sign_in_url"
    t.string "contact_email"
    t.string "fediverse_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "favorites", force: :cascade do |t|
    t.string "favoritable_type", null: false
    t.bigint "favoritable_id", null: false
    t.string "favoritor_type", null: false
    t.bigint "favoritor_id", null: false
    t.string "scope", default: "printed", null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked"], name: "index_favorites_on_blocked"
    t.index ["favoritable_id", "favoritable_type"], name: "fk_favoritables"
    t.index ["favoritable_type", "favoritable_id", "favoritor_type", "favoritor_id", "scope"], name: "uniq_favorites__and_favoritables", unique: true
    t.index ["favoritor_id", "favoritor_type"], name: "fk_favorites"
    t.index ["favoritor_type", "favoritor_id"], name: "index_favorites_on_favoritor"
    t.index ["scope"], name: "index_favorites_on_scope"
  end

  create_table "federails_activities", force: :cascade do |t|
    t.string "entity_type", null: false
    t.bigint "entity_id", null: false
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["actor_id"], name: "index_federails_activities_on_actor_id"
    t.index ["entity_type", "entity_id"], name: "index_federails_activities_on_entity"
    t.index ["uuid"], name: "index_federails_activities_on_uuid", unique: true
  end

  create_table "federails_actors", force: :cascade do |t|
    t.string "name"
    t.string "federated_url"
    t.string "username"
    t.string "server"
    t.string "inbox_url"
    t.string "outbox_url"
    t.string "followers_url"
    t.string "followings_url"
    t.string "profile_url"
    t.bigint "entity_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_type"
    t.text "public_key"
    t.text "private_key"
    t.string "uuid"
    t.json "extensions"
    t.boolean "local", default: false, null: false
    t.string "actor_type"
    t.datetime "tombstoned_at"
    t.index ["entity_type", "entity_id"], name: "index_federails_actors_on_entity", unique: true
    t.index ["federated_url"], name: "index_federails_actors_on_federated_url", unique: true
    t.index ["uuid"], name: "index_federails_actors_on_uuid", unique: true
  end

  create_table "federails_followings", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.bigint "target_actor_id", null: false
    t.integer "status", default: 0
    t.string "federated_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["actor_id", "target_actor_id"], name: "index_federails_followings_on_actor_id_and_target_actor_id", unique: true
    t.index ["target_actor_id"], name: "index_federails_followings_on_target_actor_id"
    t.index ["uuid"], name: "index_federails_followings_on_uuid", unique: true
  end

  create_table "federails_hosts", force: :cascade do |t|
    t.string "domain", null: false
    t.string "nodeinfo_url"
    t.string "software_name"
    t.string "software_version"
    t.text "protocols", default: "[]"
    t.text "services", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_federails_hosts_on_domain", unique: true
  end

  create_table "federails_moderation_domain_blocks", force: :cascade do |t|
    t.string "domain", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_federails_moderation_domain_blocks_on_domain", unique: true
  end

  create_table "federails_moderation_reports", force: :cascade do |t|
    t.string "federated_url"
    t.bigint "federails_actor_id"
    t.string "content"
    t.string "object_type"
    t.bigint "object_id"
    t.datetime "resolved_at"
    t.string "resolution"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["federails_actor_id"], name: "index_federails_moderation_reports_on_federails_actor_id"
    t.index ["object_type", "object_id"], name: "index_federails_moderation_reports_on_object"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_groups_on_creator_id"
  end

  create_table "libraries", force: :cascade do |t|
    t.string "path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notes"
    t.string "caption"
    t.string "name"
    t.text "tag_regex"
    t.text "icon"
    t.string "storage_service", default: "filesystem", null: false
    t.string "s3_endpoint"
    t.string "s3_region"
    t.string "s3_bucket"
    t.string "s3_access_key_id"
    t.string "s3_secret_access_key"
    t.string "public_id"
    t.boolean "s3_path_style", default: true, null: false
    t.index ["path"], name: "index_libraries_on_path", unique: true
    t.index ["public_id"], name: "index_libraries_on_public_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "url"
    t.string "linkable_type"
    t.bigint "linkable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "synced_at"
    t.index ["linkable_id", "linkable_type", "url"], name: "index_links_on_linkable_id_and_linkable_type_and_url"
    t.index ["linkable_type", "linkable_id"], name: "index_links_on_linkable"
    t.index ["url"], name: "index_links_on_url"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "group_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "merge_histories", force: :cascade do |t|
    t.bigint "target_model_id", null: false
    t.bigint "source_library_id"
    t.string "source_path", null: false
    t.string "source_name", null: false
    t.string "path_prefix"
    t.json "source_metadata", default: {}, null: false
    t.json "moved_files", default: [], null: false
    t.datetime "undone_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_library_id"], name: "index_merge_histories_on_source_library_id"
    t.index ["target_model_id", "created_at"], name: "index_merge_histories_on_target_model_id_and_created_at"
    t.index ["target_model_id"], name: "index_merge_histories_on_target_model_id"
  end

  create_table "model_files", force: :cascade do |t|
    t.string "filename"
    t.bigint "model_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "presupported", default: false, null: false
    t.boolean "y_up", default: false, null: false
    t.string "digest"
    t.text "notes"
    t.text "caption"
    t.bigint "size"
    t.bigint "presupported_version_id"
    t.json "attachment_data"
    t.string "public_id"
    t.virtual "filename_lower", type: :string, as: "lower((filename)::text)", stored: true
    t.boolean "previewable", default: false, null: false
    t.boolean "archive_entries_truncated", default: false, null: false
    t.integer "archive_entries_listed_count", default: 0, null: false
    t.index ["digest"], name: "index_model_files_on_digest"
    t.index ["filename", "model_id"], name: "index_model_files_on_filename_and_model_id", unique: true
    t.index ["filename_lower"], name: "index_model_files_on_filename_lower"
    t.index ["model_id"], name: "index_model_files_on_model_id"
    t.index ["presupported_version_id"], name: "index_model_files_on_presupported_version_id"
    t.index ["public_id"], name: "index_model_files_on_public_id"
  end

  create_table "models", force: :cascade do |t|
    t.string "name", null: false
    t.string "path", null: false
    t.bigint "library_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "preview_file_id"
    t.bigint "creator_id"
    t.text "notes"
    t.text "caption"
    t.bigint "collection_id"
    t.string "slug"
    t.string "license"
    t.string "public_id"
    t.virtual "name_lower", type: :string, as: "lower((name)::text)", stored: true
    t.boolean "sensitive", default: false, null: false
    t.string "indexable"
    t.string "ai_indexable"
    t.datetime "scan_started_at"
    t.index ["collection_id"], name: "index_models_on_collection_id"
    t.index ["created_at"], name: "index_models_on_created_at"
    t.index ["creator_id"], name: "index_models_on_creator_id"
    t.index ["library_id"], name: "index_models_on_library_id"
    t.index ["name"], name: "index_models_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["name_lower"], name: "index_models_on_name_lower"
    t.index ["path", "library_id"], name: "index_models_on_path_and_library_id", unique: true
    t.index ["path"], name: "index_models_on_path_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["preview_file_id"], name: "index_models_on_preview_file_id"
    t.index ["public_id"], name: "index_models_on_public_id"
    t.index ["slug"], name: "index_models_on_slug"
    t.index ["updated_at"], name: "index_models_on_updated_at"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.string "type"
    t.string "record_type"
    t.bigint "record_id"
    t.jsonb "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notifications_count"
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.string "type"
    t.bigint "event_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.datetime "read_at", precision: nil
    t.datetime "seen_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "print_curation_notes", force: :cascade do |t|
    t.bigint "model_id", null: false
    t.bigint "user_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_print_curation_notes_on_model_id"
    t.index ["user_id"], name: "index_print_curation_notes_on_user_id"
  end

  create_table "print_hosts", force: :cascade do |t|
    t.string "name", null: false
    t.string "protocol", null: false
    t.string "endpoint", null: false
    t.string "credentials"
    t.string "mainboard_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "brand"
    t.string "machine_model"
    t.string "firmware"
    t.string "mac_address"
    t.integer "resolution_w"
    t.integer "resolution_h"
    t.decimal "build_x_mm", precision: 8, scale: 2
    t.decimal "build_y_mm", precision: 8, scale: 2
    t.decimal "build_z_mm", precision: 8, scale: 2
    t.json "native_formats", default: [], null: false
    t.integer "fep_cycles", default: 0, null: false
    t.decimal "lcd_hours", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "storage_bytes_used"
    t.bigint "storage_bytes_total"
    t.index ["mainboard_id"], name: "index_print_hosts_on_mainboard_id"
    t.index ["protocol"], name: "index_print_hosts_on_protocol"
  end

  create_table "print_jobs", force: :cascade do |t|
    t.bigint "print_host_id", null: false
    t.bigint "model_id"
    t.bigint "model_file_id"
    t.bigint "user_id"
    t.bigint "sliced_artifact_id"
    t.string "state", default: "queued", null: false
    t.datetime "plate_cleared_at"
    t.string "resin_profile"
    t.integer "layer_count"
    t.integer "current_layer"
    t.integer "estimated_duration_seconds"
    t.integer "actual_duration_seconds"
    t.decimal "estimated_resin_ml", precision: 10, scale: 2
    t.decimal "actual_resin_ml", precision: 10, scale: 2
    t.string "outcome"
    t.text "failure_note"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_file_id"], name: "index_print_jobs_on_model_file_id"
    t.index ["model_id"], name: "index_print_jobs_on_model_id"
    t.index ["print_host_id", "state"], name: "index_print_jobs_on_print_host_id_and_state"
    t.index ["print_host_id"], name: "index_print_jobs_on_print_host_id"
    t.index ["print_host_id"], name: "index_print_jobs_one_printing_per_host", unique: true, where: "((state)::text = 'printing'::text)"
    t.index ["sliced_artifact_id"], name: "index_print_jobs_on_sliced_artifact_id"
    t.index ["state"], name: "index_print_jobs_on_state"
    t.index ["user_id"], name: "index_print_jobs_on_user_id"
  end

  create_table "print_vats", force: :cascade do |t|
    t.string "identity", null: false
    t.integer "fep_cycles", default: 0, null: false
    t.bigint "print_host_id", null: false
    t.bigint "resin_bottle_id"
    t.string "status", default: "ready", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["print_host_id", "identity"], name: "index_print_vats_on_print_host_id_and_identity", unique: true
    t.index ["print_host_id"], name: "index_print_vats_on_print_host_id"
    t.index ["resin_bottle_id"], name: "index_print_vats_on_resin_bottle_id"
  end

  create_table "problems", force: :cascade do |t|
    t.string "problematic_type"
    t.bigint "problematic_id"
    t.integer "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "note"
    t.boolean "ignored", default: false, null: false
    t.string "public_id"
    t.boolean "in_progress", default: false, null: false
    t.integer "state", default: 0, null: false
    t.index ["category", "problematic_id", "problematic_type"], name: "index_problems_on_category_and_problematic_id_and_type", unique: true
    t.index ["problematic_type", "problematic_id"], name: "index_problems_on_problematic"
    t.index ["public_id"], name: "index_problems_on_public_id"
    t.index ["state"], name: "index_problems_on_state"
  end

  create_table "resin_bottles", force: :cascade do |t|
    t.string "brand", null: false
    t.string "color"
    t.decimal "remaining_ml", precision: 10, scale: 2, null: false
    t.decimal "capacity_ml", precision: 10, scale: 2, null: false
    t.date "opened_on"
    t.bigint "print_host_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["print_host_id"], name: "index_resin_bottles_on_print_host_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "sliced_artifacts", force: :cascade do |t|
    t.bigint "model_id", null: false
    t.bigint "print_host_id", null: false
    t.bigint "model_file_id"
    t.string "format", null: false
    t.integer "estimated_layers"
    t.integer "estimated_duration_seconds"
    t.decimal "estimated_resin_ml", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_file_id"], name: "index_sliced_artifacts_on_model_file_id"
    t.index ["model_id", "print_host_id"], name: "index_sliced_artifacts_on_model_id_and_print_host_id"
    t.index ["model_id"], name: "index_sliced_artifacts_on_model_id"
    t.index ["print_host_id"], name: "index_sliced_artifacts_on_print_host_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.json "pagination_settings"
    t.json "renderer_settings"
    t.json "tag_cloud_settings"
    t.json "problem_settings"
    t.json "file_list_settings"
    t.string "reset_password_token"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "interface_language"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "auth_provider"
    t.string "auth_uid"
    t.string "sensitive_content_handling"
    t.string "public_id"
    t.boolean "approved", default: true, null: false
    t.integer "quota", default: 1, null: false
    t.boolean "quota_use_site_default", default: true, null: false
    t.json "tour_state"
    t.integer "sort_order", default: 0, null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["public_id"], name: "index_users_on_public_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  add_foreign_key "archive_entries", "model_files", on_delete: :cascade
  add_foreign_key "collections", "collections"
  add_foreign_key "collections", "creators"
  add_foreign_key "comments", "federails_actors"
  add_foreign_key "fasp_client_backfill_requests", "fasp_client_providers"
  add_foreign_key "fasp_client_event_subscriptions", "fasp_client_providers"
  add_foreign_key "federails_activities", "federails_actors", column: "actor_id"
  add_foreign_key "federails_followings", "federails_actors", column: "actor_id"
  add_foreign_key "federails_followings", "federails_actors", column: "target_actor_id"
  add_foreign_key "federails_moderation_reports", "federails_actors"
  add_foreign_key "groups", "creators"
  add_foreign_key "memberships", "groups", on_delete: :cascade
  add_foreign_key "memberships", "users", on_delete: :cascade
  add_foreign_key "merge_histories", "libraries", column: "source_library_id", on_delete: :nullify
  add_foreign_key "merge_histories", "models", column: "target_model_id"
  add_foreign_key "model_files", "model_files", column: "presupported_version_id"
  add_foreign_key "model_files", "models"
  add_foreign_key "models", "collections"
  add_foreign_key "models", "creators"
  add_foreign_key "models", "libraries"
  add_foreign_key "models", "model_files", column: "preview_file_id", on_delete: :nullify
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "print_curation_notes", "models"
  add_foreign_key "print_curation_notes", "users"
  add_foreign_key "print_jobs", "model_files"
  add_foreign_key "print_jobs", "models"
  add_foreign_key "print_jobs", "print_hosts"
  add_foreign_key "print_jobs", "sliced_artifacts"
  add_foreign_key "print_jobs", "users"
  add_foreign_key "print_vats", "print_hosts"
  add_foreign_key "print_vats", "resin_bottles"
  add_foreign_key "resin_bottles", "print_hosts"
  add_foreign_key "sliced_artifacts", "model_files"
  add_foreign_key "sliced_artifacts", "models"
  add_foreign_key "sliced_artifacts", "print_hosts"
  add_foreign_key "taggings", "tags"
  add_foreign_key "users_roles", "roles", on_delete: :cascade
  add_foreign_key "users_roles", "users", on_delete: :cascade
end
