class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_user
    if !logged_in?
      flash[:error] = 'You must be logged in to do that.'
      redirect_to root_path
    end
  end

  def require_logged_out
    if logged_in?
      flash[:error] = 'You must be logged out to do that.'
      redirect_to root_path
    end
  end

  def require_logged_in_as(user)
    if current_user != user
      flash[:error] = "You aren't allowed to do that."
      redirect_to root_path
    end
  end
end
