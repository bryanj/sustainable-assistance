#encoding: utf-8
class UserController < ApplicationController
  def login
    user = User.where(username: params[:username]).first
    if user and user.password? params[:password]
      session[:user_id] = user.id
      session[:username] = user.username
      flash[:notice] = "로그인되었습니다."
    else
      flash[:notice] = "사용자명 또는 비밀번호가 일치하지 않습니다."
    end
    redirect_to :back
  end

  def logout
    session[:user_id] = nil
    session[:username] = nil
    flash[:notice] = "로그아웃되었습니다."
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
      flash[:notice] = "비밀번호가 변경되었습니다."
      redirect_to "/"
    else
      flash[:notice] = "현재 비밀번호가 일치하지 않거나, 새 비밀번호와 확인이 일치하지 않습니다."
      redirect_to :back
    end
  end
end
