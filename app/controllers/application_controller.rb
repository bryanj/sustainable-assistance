#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery

  def check_authentication
    if session[:user_id].nil?
      flash[:notice] = "로그인이 필요합니다."
      redirect_to :root
    end
  end
end
