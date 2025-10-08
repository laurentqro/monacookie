class CreateWebsites < ActiveRecord::Migration[8.1]
  def change
    create_table :websites do |t|
      t.references :account, null: false, foreign_key: true
      t.string :url, null: false
      t.string :domain, null: false
      t.boolean :verified, default: false, null: false
      t.string :verification_token
      t.string :verification_method
      t.string :api_key
      t.datetime :last_scan_at
      t.datetime :next_scan_at

      t.timestamps
    end

    add_index :websites, [:account_id, :domain], unique: true
    add_index :websites, :api_key, unique: true
    add_index :websites, :verification_token, unique: true
  end
end
