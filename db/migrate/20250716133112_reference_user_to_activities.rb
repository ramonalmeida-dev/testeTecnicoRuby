class ReferenceUserToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :user_id, :integer
    add_foreign_key :activities, :users
  end
end
