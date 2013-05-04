class CreateExams < ActiveRecord::Migration
  def change
    create_table :exams do |t|
      t.string :title
      t.boolean :published, default: false
      t.text :criterion

      t.timestamps
    end
  end
end
