#encoding: utf-8
require 'timeout'
class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :user_id
  belongs_to :assignment
  belongs_to :user

  TIMEOUT = 5

  def file=(file)
    salt = (0..5).map{('A'..'Z').to_a[rand(26)]}.join
    self.directory = "#{self.assignment_id}_#{self.user_id}_#{salt}"
    path = Rails.root.join("upload", self.directory)
    FileUtils.mkdir_p(path)
    File.open(path.join(file.original_filename), "wb") do |f|
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

  def run_test
    code = self.assignment.code
    path = Rails.root.join("upload", self.directory).to_s
    output = `cd #{path} && javac #{code}.java 2>&1`
    if $?.exitstatus != 0
      # CE
      self.message = "Compile Error. Check the message below:\n\n" + output
      self.status = 1
      self.save
      return
    end
    input_file = Rails.root.join("public", "assignment_input", "#{self.assignment_id}.txt").to_s
    sample_output = File.read(Rails.root.join("public", "assignment_output", "#{self.assignment_id}.txt"))
    begin
      Timeout::timeout(TIMEOUT) {
        output = `cd #{path} && java #{code} < #{input_file} 2>&1`
        if output.strip == sample_output.strip
          # AC
          self.message = "Accepted"
          self.status = 2
          self.save
        else
          # WA
          self.message = "Wrong Answer.\n\nExpected Output\n==========\n" + sample_output + "\n\nYour Output\n==========\n" + output
          self.status = 1
          self.save
        end
      }
    rescue Timeout::Error
      # TLE
      self.message = "Time Limit Exceeded. The program did not finish within the time limit."
      self.status = 1
      self.save
    end
  end
end
