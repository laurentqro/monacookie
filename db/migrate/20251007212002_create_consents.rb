class CreateConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :consents do |t|
      t.references :account, null: false, foreign_key: true
      t.references :website, null: false, foreign_key: true
      t.string :visitor_id, null: false
      t.datetime :consent_given_at, null: false
      t.string :ip_address_hash
      t.text :user_agent
      t.jsonb :consent_choices, null: false, default: {}
      t.integer :consent_method, null: false
      t.integer :consent_version, null: false, default: 1
      t.datetime :withdrawn_at

      t.timestamps
    end

    add_index :consents, :visitor_id
    add_index :consents, :consent_given_at
    add_index :consents, :withdrawn_at
    add_index :consents, [:website_id, :consent_given_at]
    add_index :consents, :consent_choices, using: :gin
  end
end
