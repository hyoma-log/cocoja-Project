class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_user_table
    add_user_indexes
  end

  private

  def create_user_table
    create_table :users do |t|
      add_authentication_columns(table: t)
      add_additional_devise_columns(table: t)
      add_custom_user_fields(table: t)

      t.timestamps null: false
    end
  end

  def add_authentication_columns(table:)
    table.string :email,              null: false
    table.string :encrypted_password, null: false
    table.string :reset_password_token
    table.datetime :reset_password_sent_at
    table.datetime :remember_created_at
  end

  def add_additional_devise_columns(table:)
    table.string   :confirmation_token
    table.datetime :confirmed_at
    table.datetime :confirmation_sent_at
    table.string   :unconfirmed_email
  end

  def add_custom_user_fields(table:)
    table.string :username
    table.string :uid
    table.string :profile_image_url
  end

  def add_user_indexes
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :username,             unique: true
    add_index :users, :uid,                  unique: true
  end
end
