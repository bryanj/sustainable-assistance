class Assignment < ActiveRecord::Base
  attr_accessible :title, :duedate, :content, :code, :report
end
