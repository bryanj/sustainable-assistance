class CreateScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.integer :exam_id
      t.integer :user_id
      t.text :score

      t.timestamps
    end
  end
end
