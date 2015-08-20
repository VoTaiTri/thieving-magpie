class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :title
      t.string :job_category
      t.string :job_type
      t.string :business_category
      t.text :workplace
      t.text :requirement
      t.integer :inexperience, limit: 1
      t.text :work_time
      t.text :salary
      t.text :holiday
      t.text :treatment
      t.text :raw_html
      t.text :content
      t.text :url
      t.references :company
      t.integer :worker

      t.timestamps null: false
    end

    add_foreign_key :jobs, :companies
  end
end
