class UserController < ApplicationController
  def login
    user = User.where(username: params[:username]).first
    if user and user.password? params[:password]
      session[:user_id] = user.id
      session[:username] = user.username
    end
    redirect_to :back
  end

  def logout
    session[:user_id] = nil
    session[:username] = nil
    redirect_to :back
  end
end
