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

ActiveRecord::Schema[7.0].define(version: 2023_03_24_000000) do
  create_table "collections", force: :cascade do |t|
    t.string "name"
    t.text "notes"
    t.text "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "collection_id"
    t.index ["collection_id"], name: "index_collections_on_collection_id"
  end

  create_table "creators", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.text "caption"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
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
    t.boolean "presupported", default: false
    t.boolean "printed", default: false
    t.boolean "y_up", default: false, null: false
    t.string "digest"
    t.text "notes"
    t.text "caption"
    t.index ["digest"], name: "index_model_files_on_digest"
    t.index ["model_id"], name: "index_model_files_on_model_id"
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
    t.index ["collection_id"], name: "index_models_on_collection_id"
    t.index ["creator_id"], name: "index_models_on_creator_id"
    t.index ["library_id"], name: "index_models_on_library_id"
    t.index ["preview_file_id"], name: "index_models_on_preview_file_id"
  end

  create_table "problems", force: :cascade do |t|
    t.string "problematic_type"
    t.integer "problematic_id"
    t.integer "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["problematic_type", "problematic_id"], name: "index_problems_on_problematic"
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
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "taggings_count", default: 0
    t.text "notes"
    t.text "caption"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.boolean "admin", default: false
    t.json "pagination_settings", default: {"models"=>true, "creators"=>true, "collections"=>true, "per_page"=>12}
    t.json "renderer_settings", default: {"grid_width"=>200, "grid_depth"=>200}
    t.json "tag_cloud_settings", default: {"threshold"=>0, "heatmap"=>true, "keypair"=>true, "sorting"=>"frequency", "hide_unrelated"=>true}
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "collections", "collections"
  add_foreign_key "model_files", "models"
  add_foreign_key "models", "collections"
  add_foreign_key "models", "creators"
  add_foreign_key "models", "libraries"
  add_foreign_key "taggings", "tags"
end
