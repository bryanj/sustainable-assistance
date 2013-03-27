#encoding: utf-8
class SubmissionMailer < ActionMailer::Base
  default from: ENV["notification_sender"]
  default to: ENV["notification_receiver"]
  def submission_notification(submission)
    subject = "[과제 제출 알림] #{submission.assignment.title} - #{submission.user.name}"
    filename = submission.assignment.code + ".java"
    attachments[filename] = File.read(Rails.root.join("upload", submission.directory, filename))
    @submission = submission
    mail(subject: subject)
  end

  def submission_confirmation(submission)
    subject = "[과제 제출 확인] #{submission.assignment.title}"
    filename = submission.assignment.code + ".java"
    attachments[filename] = File.read(Rails.root.join("upload", submission.directory, filename))
    @submission = submission
    mail(to: submission.user.mail_address, subject: subject)
  end
end
