#encoding: utf-8
class Result < ActiveRecord::Base
  attr_accessible :user_id, :assignment_id, :period_id, :submission_id, :score, :message
  belongs_to :user
  belongs_to :assignment
  belongs_to :period
  belongs_to :submission

  TIMEOUT = 5

  def is_public
    self.period.result_time < Time.now
  end

  def displayed_score
    self.is_public ? self.score : "비공개"
  end

  def result_time
    self.period.result_time.strftime("%Y-%m-%d %H:%M:%S")
  end

  def run_score
    code = self.assignment.code
    path = Rails.root.join("upload", self.submission.directory).to_s
    data = File.read(path + "/#{code}.java")
    if data.include? "Runtime" or data.include? "File"
      self.message = "This code will be tested after inspection of TA."
      self.score = 0
      self.save
      return
    end
    output = `cd #{path} && javac #{code}.java 2>&1`
    if $?.exitstatus != 0 and output.include?("unmappable character for encoding UTF8")
      output = `cd #{path} && javac #{code}.java -encoding EUC-KR 2>&1`
    end
    if $?.exitstatus != 0
      # CE
      self.message = "Compile Error. Check the message below:\n\n" + output
      self.score = 0
      self.save
      return
    end

    score = 0
    message = ""
    index = 1
    Dir.entries(Rails.root.join("testset", self.period_id.to_s, "input")).sort_by{|f| f.to_i}.each do |f|
      next if f[0] == "."
      input_file = Rails.root.join("testset", self.period_id.to_s, "input", f).to_s
      input = File.read(input_file)
      sample_output = File.read(Rails.root.join("testset", self.period_id.to_s, "output", f))
      begin
        Timeout::timeout(TIMEOUT) {
          output = `cd #{path} && java #{code} < #{input_file} 2>&1`
          if output.strip == sample_output.strip
            # AC
            score += 1
            message += "Case #{index}: Accepted\n"
          else
            # WA
            message += "Case #{index}: Wrong Answer\n"
            message += "--- Input ---\n"
            message += input + "\n"
            message += "--- Expected Output ---\n"
            message += sample_output + "\n"
            message += "--- Your Output ---\n"
            message += output + "\n"
          end
        }
      rescue Timeout::Error
        # TLE
        message += "Case #{index}: Time Limit Exceeded\n"
        message += "--- Input ---\n"
        message += input + "\n"
      end
      index += 1
    end
    self.update_attributes(score: score, message: message)
  end
end
