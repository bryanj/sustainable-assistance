class ApplicationController < ActionController::Base
  protect_from_forgery

  def check_authentication
    if session[:user_id].nil?
      redirect_to :root
    end
  end
end
