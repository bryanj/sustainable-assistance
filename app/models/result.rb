#encoding: utf-8
require 'zip/zip'
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
      argument = File.read(Rails.root.join("testset", self.period_id.to_s, "argument", f)).strip rescue nil
      sample_output = File.read(Rails.root.join("testset", self.period_id.to_s, "output", f))
      begin
        Timeout::timeout(TIMEOUT) {
          output = `cd #{path} && java #{code} #{argument} < #{input_file} 2>&1`
          if equivalent(output.strip, sample_output.strip)
            # AC
            score += 1
            message += "Case #{index}: Accepted\n"
          else
            # WA
            message += "Case #{index}: Wrong Answer\n"
            message += "--- Input ---\n"
            message += "(Argument: " + hide_path(argument) + ")\n" if argument != nil
            message += hide_path(truncate(input)) + "\n"
            message += "--- Expected Output ---\n"
            message += truncate(sample_output) + "\n"
            message += "--- Your Output ---\n"
            message += truncate(output) + "\n"
          end
        }
      rescue Timeout::Error
        # TLE
        message += "Case #{index}: Time Limit Exceeded\n"
        message += "--- Input ---\n"
        message += "(Argument: " + hide_path(argument) + ")\n" if argument != nil
        message += hide_path(truncate(input)) + "\n"
      end
      index += 1
    end
    `killall java`
    self.update_attributes(score: score, message: message)
  end

  def self.summarize(assignment_id)
    code = Assignment.find(assignment_id).code
    results = Hash.new
    Result.where(assignment_id: assignment_id).each do |r|
      results[r.user_id] = r
    end
    Zip::ZipFile.open("summary#{assignment_id}.zip", Zip::ZipFile::CREATE) do |zipfile|
      zipfile.get_output_stream("summary.csv") do |f|
        results.sort.each do |k, r|
          f.puts "#{r.user_id},#{r.user.name},#{r.score}"
        end
      end
      results.each_value do |r|
        zipfile.add("#{r.user_id}/#{code}.java", "upload/#{r.submission.directory}/#{code}.java")
      end
    end
  end

private
  LENGTH = 300

  def truncate(str)
    if str.length <= LENGTH
      str
    else
      str[0..LENGTH-1] + "..(#{str.length - LENGTH} more characters)"
    end
  end

  def hide_path(str)
    str.gsub(Rails.root.join("public").to_s+"/", "")
  end

  def equivalent(out, sample_out)
    return true if out == sample_out

    lines = out.split("\n")
    sample_lines = sample_out.split("\n")
    return false if lines.size != sample_lines.size

    0.upto(lines.size - 1) do |i|
      line = lines[i]
      sample_line = sample_lines[i]
      if line != sample_line
        tokens = line.split(" ")
        sample_tokens = sample_line.split(" ")
        return false if tokens.size != sample_tokens.size
        0.upto(tokens.size - 1) do |j|
          return false if !same_token(tokens[j], sample_tokens[j])
        end
      end
    end

    return true
  end

  def same_token(token, sample_token)
    return true if token == sample_token
    begin
      value = Float(token)
      sample_value = Float(sample_token)
      return true if value == sample_value
      error = (value / sample_value - 1).abs
      return true if error < 1e-6
      return false
    rescue
      return false
    end
  end
end
