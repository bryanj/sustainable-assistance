#encoding: utf-8
class SubmissionController < ApplicationController
  before_filter :check_authentication

  PER_PAGE = 10

  def new
    @assignments = Assignment.all
  end

  def create
    period = Period.where(assignment_id: params[:assignment_id])
              .where(["start_time < ? and end_time > ?", Time.now, Time.now - 10.minute]).first
    if period.nil?
      flash[:notice] = "과제의 제출 기간이 아닙니다."
      redirect_to :back
      return
    end
    if params[:file].nil?
      flash[:notice] = "첨부파일이 없습니다."
      redirect_to :back
      return
    end
    filename = Assignment.find(params[:assignment_id]).code + ".java"
    if params[:file].original_filename != filename
      flash[:notice] = "올바른 파일명이 아닙니다."
      redirect_to :back
      return
    end
    submission = Submission.new(assignment_id: params[:assignment_id], period_id: period.id, user_id: session[:user_id])
    submission.file = params[:file]
    if submission.save
      Stalker.enqueue("submission.send_confirmation", id: submission.id)
      Stalker.enqueue("submission.send_notification", id: submission.id)
      Stalker.enqueue("submission.run_test", id: submission.id)
      flash[:notice] = "제출되었습니다!"
      redirect_to "/submission/list"
    else
      redirect_to :back
    end
  end

  def list
    page = (params[:page] ? params[:page].to_i : 1) - 1
    @submissions = Submission.where(user_id: session[:user_id]).includes(:assignment).order("id desc").limit(PER_PAGE).offset(page * PER_PAGE)
    @total_page = (Submission.where(user_id: session[:user_id]).count - 1) / PER_PAGE + 1
    @current_page = page + 1
  end

  def show
    @submission = Submission.find(params[:id])
    if @submission.user_id != session[:user_id]
      flash[:notice] = "올바르지 않은 접근입니다."
      redirect_to :root
      return
    end
  end

  def score
    page = (params[:page] ? params[:page].to_i : 1) - 1
    @results = Result.where(user_id: session[:user_id]).includes(:assignment, :period).order("id desc").limit(PER_PAGE).offset(page * PER_PAGE)
    @total_page = (Result.where(user_id: session[:user_id]).count - 1) / PER_PAGE + 1
    @current_page = page + 1
  end

  def result
    @result = Result.find(params[:id])
    if @result.user_id != session[:user_id]
      flash[:notice] = "올바르지 않은 접근입니다."
      redirect_to :root
      return
    end
  end
end
