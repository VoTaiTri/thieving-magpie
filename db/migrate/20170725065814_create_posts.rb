class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.string :content
      t.references :user, index: true, foreign_key: true, null: false

      t.timestamps
    end
  end
end
