require File.expand_path("../environment", __FILE__)

job "submission.run_test" do |args|
  Submission.find(args['id']).run_test
end