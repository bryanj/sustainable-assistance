class Score < ActiveRecord::Base
  attr_accessible :exam_id, :score, :user_id
  belongs_to :exam
  belongs_to :user
end
