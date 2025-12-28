class UpdateVotesUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :votes, [:user_id, :post_id], if_exists: true

    add_column :votes, :voted_on, :date, null: false, default: -> { 'CURRENT_DATE' }

    add_index :votes, [:user_id, :post_id, :voted_on], unique: true, name: 'index_votes_on_user_id_post_id_and_date'
  end
end
