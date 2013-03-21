class SubmissionMailer < ActionMailer::Base
  default from: ENV["notification_sender"]
  default to: ENV["notification_receiver"]
  def submission_notification(submission)
    subject = "[DS_HW#{submission.assignment_id}] #{submission.user.name}"
    filename = submission.assignment.code + ".java"
    attachments[filename] = File.read(Rails.root.join("upload", submission.directory, filename))
    mail(to: "sky@izz.kr", subject: subject)
  end
end
