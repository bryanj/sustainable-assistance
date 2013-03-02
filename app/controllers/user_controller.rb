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

  def edit_password
  end

  def update_password
    logger.info session[:user_id]
    user = User.find(session[:user_id])
    if user.password? params[:current_password] and params[:new_password] == params[:new_password_confirm]
      user.password = params[:new_password]
      user.save
      redirect_to "/"
    else
      redirect_to :back
    end
  end
end
