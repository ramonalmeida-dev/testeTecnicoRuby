class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.string :title
      t.string :description
      t.boolean :status
      t.date :start_date
      t.date :end_date
      t.integer :kind
      t.float :completed_percent
      t.integer :priority
      t.integer :urgency
      t.integer :points

      t.timestamps
    end
  end
end
