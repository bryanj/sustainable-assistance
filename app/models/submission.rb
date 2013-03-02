#encoding: utf-8
class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :user_id
  belongs_to :assignment
  belongs_to :user

  def file=(file)
    salt = (0..5).map{('A'..'Z').to_a[rand(26)]}.join
    self.directory = "#{self.assignment_id}_#{self.user_id}_#{salt}"
    path = Rails.root.join("upload", self.directory)
    FileUtils.mkdir_p(path)
    File.open(path.join(file.original_filename), "w") do |f|
      f.write(file.read)
    end
  end

  def status_string
    ["제출 완료", "테스트 실패", "테스트 통과"][self.status]
  end

  def submitted?
    self.status == 0
  end

  def failed?
    self.status == 1
  end

  def validated?
    self.status == 2
  end
end
