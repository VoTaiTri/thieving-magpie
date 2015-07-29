class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.string :postal_code
      t.string :raw_address
      t.string :full_address
      t.string :address1
      t.string :address2
      t.string :address34
      t.string :address3
      t.string :address4
      t.text :full_tel
      t.text :tel
      t.string :establishment
      t.string :employees_number
      t.string :sales
      t.string :home_page
      t.text :url
      
      t.timestamps null: false
    end
  end
end
