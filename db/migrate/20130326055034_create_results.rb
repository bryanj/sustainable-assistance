class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.integer :user_id
      t.integer :assignment_id
      t.integer :period_id
      t.integer :submission_id
      t.integer :score
      t.text :message

      t.timestamps
    end
  end
end
