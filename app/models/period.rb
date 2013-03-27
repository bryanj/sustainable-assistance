class Period < ActiveRecord::Base
  attr_accessible :assignment_id, :end_time, :start_time, :result_time
  belongs_to :assignment

  def index
    self.id % 5
  end
end
