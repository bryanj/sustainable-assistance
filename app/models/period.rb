class Period < ActiveRecord::Base
  attr_accessible :assignment_id, :end_time, :start_time, :result_time
  belongs_to :assignment
end
