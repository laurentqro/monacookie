class CreateCookies < ActiveRecord::Migration[8.1]
  def change
    create_table :cookies do |t|
      t.references :website, null: false, foreign_key: true
      t.string :name, null: false
      t.string :domain, null: false
      t.integer :category, null: false, default: 0
      t.text :description
      t.string :expiry
      t.string :path, default: "/"
      t.boolean :secure, default: false
      t.boolean :http_only, default: false
      t.string :same_site
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :cookies, [:website_id, :name, :domain], unique: true
    add_index :cookies, :category
  end
end
