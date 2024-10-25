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

ActiveRecord::Schema[7.1].define(version: 2024_10_25_110218) do
  create_table "caber_relations", force: :cascade do |t|
    t.string "subject_type"
    t.integer "subject_id"
    t.string "permission"
    t.string "object_type", null: false
    t.integer "object_id", null: false
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
    t.integer "collection_id"
    t.string "slug"
    t.string "public_id"
    t.virtual "name_lower", type: :string, as: "LOWER(name)", stored: true
    t.index ["collection_id"], name: "index_collections_on_collection_id"
    t.index ["name"], name: "index_collections_on_name", unique: true
    t.index ["name_lower"], name: "index_collections_on_name_lower"
    t.index ["public_id"], name: "index_collections_on_public_id"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.string "public_id", null: false
    t.string "commenter_type", null: false
    t.integer "commenter_id", null: false
    t.string "commentable_type", null: false
    t.integer "commentable_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system", default: false, null: false
    t.boolean "sensitive", default: false, null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["commenter_type", "commenter_id"], name: "index_comments_on_commenter"
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
    t.virtual "name_lower", type: :string, as: "LOWER(name)", stored: true
    t.index ["name"], name: "index_creators_on_name", unique: true
    t.index ["name_lower"], name: "index_creators_on_name_lower"
    t.index ["public_id"], name: "index_creators_on_public_id"
    t.index ["slug"], name: "index_creators_on_slug", unique: true
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "favorites", force: :cascade do |t|
    t.string "favoritable_type", null: false
    t.integer "favoritable_id", null: false
    t.string "favoritor_type", null: false
    t.integer "favoritor_id", null: false
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
    t.integer "entity_id", null: false
    t.string "action", null: false
    t.integer "actor_id", null: false
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
    t.integer "entity_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_type", default: "User"
    t.text "public_key"
    t.text "private_key"
    t.string "uuid"
    t.index ["entity_type", "entity_id"], name: "index_federails_actors_on_entity", unique: true
    t.index ["federated_url"], name: "index_federails_actors_on_federated_url", unique: true
    t.index ["uuid"], name: "index_federails_actors_on_uuid", unique: true
  end

  create_table "federails_followings", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.integer "target_actor_id", null: false
    t.integer "status", default: 0
    t.string "federated_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["actor_id", "target_actor_id"], name: "index_federails_followings_on_actor_id_and_target_actor_id", unique: true
    t.index ["target_actor_id"], name: "index_federails_followings_on_target_actor_id"
    t.index ["uuid"], name: "index_federails_followings_on_uuid", unique: true
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
    t.index ["public_id"], name: "index_libraries_on_public_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "url"
    t.string "linkable_type"
    t.integer "linkable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linkable_type", "linkable_id"], name: "index_links_on_linkable"
  end

  create_table "model_files", force: :cascade do |t|
    t.string "filename"
    t.integer "model_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "presupported", default: false, null: false
    t.boolean "y_up", default: false, null: false
    t.string "digest"
    t.text "notes"
    t.text "caption"
    t.bigint "size"
    t.integer "presupported_version_id"
    t.json "attachment_data"
    t.string "public_id"
    t.index ["digest"], name: "index_model_files_on_digest"
    t.index ["filename", "model_id"], name: "index_model_files_on_filename_and_model_id", unique: true
    t.index ["model_id"], name: "index_model_files_on_model_id"
    t.index ["presupported_version_id"], name: "index_model_files_on_presupported_version_id"
    t.index ["public_id"], name: "index_model_files_on_public_id"
  end

  create_table "models", force: :cascade do |t|
    t.string "name", null: false
    t.string "path", null: false
    t.integer "library_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "preview_file_id"
    t.integer "creator_id"
    t.text "notes"
    t.text "caption"
    t.integer "collection_id"
    t.string "slug"
    t.string "license"
    t.string "public_id"
    t.virtual "name_lower", type: :string, as: "LOWER(name)", stored: true
    t.boolean "sensitive", default: false, null: false
    t.index ["collection_id"], name: "index_models_on_collection_id"
    t.index ["creator_id"], name: "index_models_on_creator_id"
    t.index ["library_id"], name: "index_models_on_library_id"
    t.index ["name_lower"], name: "index_models_on_name_lower"
    t.index ["path", "library_id"], name: "index_models_on_path_and_library_id", unique: true
    t.index ["preview_file_id"], name: "index_models_on_preview_file_id"
    t.index ["public_id"], name: "index_models_on_public_id"
    t.index ["slug"], name: "index_models_on_slug"
  end

  create_table "problems", force: :cascade do |t|
    t.string "problematic_type"
    t.integer "problematic_id"
    t.integer "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "note"
    t.boolean "ignored", default: false, null: false
    t.string "public_id"
    t.index ["category", "problematic_id", "problematic_type"], name: "index_problems_on_category_and_problematic_id_and_type", unique: true
    t.index ["problematic_type", "problematic_id"], name: "index_problems_on_problematic"
    t.index ["public_id"], name: "index_problems_on_public_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
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

  create_table "taggings", force: :cascade do |t|
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

  create_table "tags", force: :cascade do |t|
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
    t.json "pagination_settings", default: {"models"=>true, "creators"=>true, "collections"=>true, "per_page"=>12}
    t.json "renderer_settings", default: {"grid_width"=>200, "grid_depth"=>200, "show_grid"=>true, "enable_pan_zoom"=>false, "background_colour"=>"#000000", "object_colour"=>"#cccccc", "render_style"=>"normals"}
    t.json "tag_cloud_settings", default: {"threshold"=>2, "heatmap"=>true, "keypair"=>true, "sorting"=>"frequency"}
    t.json "problem_settings", default: {"missing"=>"danger", "empty"=>"info", "nesting"=>"warning", "inefficient"=>"info", "duplicate"=>"warning", "no_image"=>"silent", "no_3d_model"=>"silent", "non_manifold"=>"warning", "inside_out"=>"warning", "no_license"=>"silent", "no_links"=>"silent", "no_creator"=>"silent", "no_tags"=>"silent"}
    t.json "file_list_settings", default: {"hide_presupported_versions"=>true}
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["public_id"], name: "index_users_on_public_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  add_foreign_key "collections", "collections"
  add_foreign_key "federails_activities", "federails_actors", column: "actor_id"
  add_foreign_key "federails_followings", "federails_actors", column: "actor_id"
  add_foreign_key "federails_followings", "federails_actors", column: "target_actor_id"
  add_foreign_key "model_files", "model_files", column: "presupported_version_id"
  add_foreign_key "model_files", "models"
  add_foreign_key "models", "collections"
  add_foreign_key "models", "creators"
  add_foreign_key "models", "libraries"
  add_foreign_key "taggings", "tags"
end
