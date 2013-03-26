class CreatePeriods < ActiveRecord::Migration
  def change
    create_table :periods do |t|
      t.integer :assignment_id
      t.datetime :start_time
      t.datetime :end_time
      t.datetime :result_time

      t.timestamps
    end
  end
end
