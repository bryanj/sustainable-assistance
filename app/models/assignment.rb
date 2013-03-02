class Assignment < ActiveRecord::Base
  attr_accessible :title, :duedate, :content, :code
end
