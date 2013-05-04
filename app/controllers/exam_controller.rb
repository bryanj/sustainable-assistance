class ExamController < ApplicationController
  before_filter :check_authentication

  def show
    @exams = Exam.all
    @exam = Exam.find(params[:id])
    if @exam.published
      @criterion = JSON.parse(@exam.criterion)
      score = Score.where(user_id: session[:user_id], exam_id: params[:id]).first
      @score = JSON.parse(score.score) rescue nil
    end
  end
end
