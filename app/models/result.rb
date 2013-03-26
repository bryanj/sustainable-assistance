#encoding: utf-8
class Result < ActiveRecord::Base
  attr_accessible :user_id, :assignment_id, :period_id, :submission_id
  belongs_to :user
  belongs_to :assignment
  belongs_to :period
  belongs_to :submission

  def is_public
    self.period.result_time < Time.now
  end

  def displayed_score
    self.is_public ? self.score : "비공개"
  end

  def result_time
    self.period.result_time.strftime("%Y-%m-%d %H:%M:%S")
  end
end
