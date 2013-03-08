class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.integer :user_id
      t.integer :assignment_id
      t.integer :period_id
      t.string :directory
      t.integer :status, default: 0
      t.text :message

      t.timestamps
    end
  end
end
