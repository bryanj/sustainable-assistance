module ExamHelper
  def sanitize(x)
    x.is_a?(Integer) ? x : (x*100).round/100.0
  end
end
