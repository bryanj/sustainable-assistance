class AddReportToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :report, :boolean, default: false
  end
end
