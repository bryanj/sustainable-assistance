#encoding: utf-8
class SubmissionController < ApplicationController
  before_filter :check_authentication

  PER_PAGE = 10

  def new
    @assignments = Assignment.all
  end

  def create
    if params[:file].nil?
      flash[:notice] = "첨부파일이 없습니다."
      redirect_to :back
      return
    end
    submission = Submission.new(assignment_id: params[:assignment_id], user_id: session[:user_id])
    submission.file = params[:file]
    submission.save
    flash[:notice] = "제출되었습니다!"
    redirect_to "/submission/list"
  end

  def list
    page = (params[:page] ? params[:page].to_i : 1) - 1
    @submissions = Submission.where(user_id: session[:user_id]).includes(:assignment).order("id desc").limit(PER_PAGE).offset(page * PER_PAGE)
    @total_page = (Submission.where(user_id: session[:user_id]).count - 1) / PER_PAGE + 1
    @current_page = page + 1
  end
end
