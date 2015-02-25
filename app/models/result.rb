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
      create_result_file
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
      create_result_file
      self.save
      return
    end

    score = 0
    message = ""
    raw_message = ""
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
          if equivalent(argument, output.strip, sample_output.strip)
            # AC
            score += 1
            message += "Case #{index}: Accepted\n"
            raw_message += "Case #{index}: Accepted\n"
          else
            # WA
            message += "Case #{index}: Wrong Answer\n"
            message += "--- Input ---\n"
            message += "(Argument: " + hide_path(argument) + ")\n" if argument != nil
            message += hide_path(truncate(input)) + "\n"
            message += "--- Expected Output ---\n"
            message += truncate(sample_output) + "\n"
            message += "--- Your Output ---\n"
            message += truncate(hide_path(output)) + "\n"
            raw_message += "Case #{index}: Wrong Answer\n"
            raw_message += "--- Input ---\n"
            raw_message += "(Argument: " + hide_path(argument) + ")\n" if argument != nil
            raw_message += hide_path(input) + "\n"
            raw_message += "--- Expected Output ---\n"
            raw_message += sample_output + "\n"
            raw_message += "--- Your Output ---\n"
            raw_message += hide_path(output) + "\n"
          end
        }
      rescue Timeout::Error
        # TLE
        message += "Case #{index}: Time Limit Exceeded\n"
        message += "--- Input ---\n"
        message += "(Argument: " + hide_path(argument) + ")\n" if argument != nil
        message += hide_path(truncate(input)) + "\n"
        raw_message += "Case #{index}: Time Limit Exceeded\n"
        raw_message += "--- Input ---\n"
        raw_message += "(Argument: " + hide_path(argument) + ")\n" if argument != nil
        raw_message += hide_path(input) + "\n"
      end
      index += 1
    end
    `killall java`
    self.update_attributes(score: score, message: message)
    create_result_file(raw_message)
  end

  def self.summarize(assignment_id)
    code = Assignment.find(assignment_id).code
    results = Hash.new
    Result.where(assignment_id: assignment_id).each do |r|
      if results[r.user_id].nil? or r.score > results[r.user_id].score
        results[r.user_id] = r
      end
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

  def equivalent(file, out, sample_out)
    return true if out == sample_out
    return equivalent_subway(file, out, sample_out) if file

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

  def equivalent_subway(file, out, sample_out)
    data = read_subway_data(file)

    lines = out.split("\n")
    sample_lines = sample_out.split("\n")
    return false if lines.size != sample_lines.size

    0.upto(lines.size / 2 - 1) do |i|
      path = lines[i * 2]
      sample_path = sample_lines[i * 2]
      length = lines[i * 2 + 1]
      sample_length = sample_lines[i * 2 + 1]
      return false if length != sample_length
      if path != sample_path
        path_weight = calculate_weight(data,path)
        return false if path_weight != length.to_i
      end
    end

    return true
  end

  def read_subway_data(file)
    data = File.read(file)
    vertex_list, edge_list = data.split("\n\n").map{|x| x.split("\n")}
    name_map = {}
    vertex_list.each do |v|
      number, name = v.split(" ")
      if name_map[name].nil?
        name_map[name] = []
      end
      name_map[name].push number
    end
    edge_map = {}
    edge_list.each do |v|
      from, to, weight = v.split(" ")
      edge_map[from+"|"+to] = weight.to_i
    end
    {name_map: name_map, edge_map: edge_map}
  end

  def calculate_weight(data, path)
    weight = path.scan("[").count * 5
    path.gsub! /\[|\]/, ""
    vertex_list = path.split " "
    (vertex_list.size-1).times do |i|
      from = data[:name_map][vertex_list[i]]
      to = data[:name_map][vertex_list[i+1]]
      return -1 if from.nil? or to.nil?
      segment_weight = from.map{|x| to.map{|y| data[:edge_map][[x, y].join("|")]}}.flatten.compact.first
      return -1 if segment_weight.nil?
      weight += segment_weight
    end
    weight
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

  def create_result_file(message = self.message)
    self.code = (0..7).map{('A'..'Z').to_a[rand(26)]}.join if self.code.nil?
    path = Rails.root.join("public", "result", self.period_id.to_s, self.code)
    FileUtils.mkdir_p(path)
    Zip::ZipFile.open(path.join("result.zip"), Zip::ZipFile::CREATE) do |zipfile|
      zipfile.get_output_stream("result.txt") do |f|
        f.puts message
      end
    end
    File.chmod(0644, path.join("result.zip"))
    self.save
  end
end
