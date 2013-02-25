# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

assignment_list = [
  [1, "Big Integer", "2013-04-05"],
  [2, "Movie Database", "2013-04-19"],
  [3, "Stack Calculator", "2013-05-03"],
  [4, "Sorting", "2013-05-17"],
  [5, "Matching", "2013-05-31"],
  [6, "Subway", "2013-06-14"]
]
assignment_list.each do |id, title, duedate|
  content = File.open("public/assignment_content/#{id}.html", "r").read rescue nil
  Assignment.create(title: title, duedate: duedate+" 05:00", content: content)
end
