# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150724014233) do

  create_table "companies", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "convert_name",      limit: 255
    t.string   "postal_code",       limit: 255
    t.string   "raw_address",       limit: 255
    t.text     "full_address",      limit: 65535
    t.string   "address1",          limit: 255
    t.string   "address2",          limit: 255
    t.string   "address34",         limit: 255
    t.string   "address3",          limit: 255
    t.string   "address4",          limit: 255
    t.text     "full_tel",          limit: 65535
    t.text     "tel",               limit: 65535
    t.string   "raw_home_page",     limit: 255
    t.string   "home_page",         limit: 255
    t.text     "url",               limit: 65535
    t.integer  "worker",            limit: 4
    t.string   "establishment",     limit: 255
    t.string   "capital",           limit: 255
    t.string   "sales",             limit: 255
    t.string   "employees_number",  limit: 255
    t.string   "business_category", limit: 255
    t.string   "recruiter",         limit: 255
    t.string   "email",             limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.string   "title",             limit: 255
    t.string   "job_category",      limit: 255
    t.string   "job_type",          limit: 255
    t.string   "business_category", limit: 255
    t.text     "workplace",         limit: 65535
    t.text     "requirement",       limit: 65535
    t.integer  "inexperience",      limit: 1
    t.text     "work_time",         limit: 65535
    t.text     "salary",            limit: 65535
    t.text     "holiday",           limit: 65535
    t.text     "treatment",         limit: 65535
    t.text     "raw_html",          limit: 65535
    t.text     "content",           limit: 65535
    t.text     "url",               limit: 65535
    t.integer  "company_id",        limit: 4
    t.integer  "worker",            limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "jobs", ["company_id"], name: "fk_rails_44ee92a833", using: :btree

  add_foreign_key "jobs", "companies"
end
