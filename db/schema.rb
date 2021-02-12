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

ActiveRecord::Schema.define(version: 2021_02_10_153744) do

  create_table "libraries", force: :cascade do |t|
    t.string "path", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "models", force: :cascade do |t|
    t.string "name", null: false
    t.string "path", null: false
    t.integer "library_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["library_id"], name: "index_models_on_library_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "filename"
    t.integer "model_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "presupported", default: false
    t.boolean "printed", default: false
    t.index ["model_id"], name: "index_parts_on_model_id"
  end

  add_foreign_key "models", "libraries"
  add_foreign_key "parts", "models"
end
