# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

assignment_list = [
  [1, "Big Integer", "2013-04-05", "BigInteger"],
  [2, "Movie Database", "2013-04-19", "MovieDatabase"],
  [3, "Stack Calculator", "2013-05-03", "CalculatorTest"],
  [4, "Sorting", "2013-05-17", "SortingTest"],
  [5, "Matching", "2013-05-31", "Matching"],
  [6, "Subway", "2013-06-14", "Subway"]
]
end_hour = 9.hour
scoring_hour = 1.hour

assignment_list.each do |id, title, duedate, code|
  content = File.open("public/assignment_content/#{id}.html", "r").read rescue nil
  duedate = DateTime.parse("#{duedate} 00:00+0900") + end_hour
  assignment = Assignment.create(title: title, content: content, code: code)
  Period.create(assignment_id: assignment.id, start_time: duedate-10.day, end_time: duedate, result_time: duedate+scoring_hour)
  4.times do |i|
    Period.create(assignment_id: assignment.id, start_time: duedate+scoring_hour, end_time: duedate+1.day, result_time: duedate+1.day+scoring_hour)
    duedate += 1.day
  end
end
