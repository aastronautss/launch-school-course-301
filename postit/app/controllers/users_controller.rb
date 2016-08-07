class UsersController < ApplicationController
  before_action :require_logged_out, only: [:new, :create]
  before_action -> { require_logged_in_as User.find(params[:id]) },
    only: [:edit, :update]

  def show
    set_user
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params

    if @user.save
      flash[:notice] = 'You are now registered.'
      session[:user_id] = @user.id
      redirect_to root_path
    else
      render :new
    end
  end

  def edit
    set_user
  end

  def update
    set_user
  end

  private

  def user_params
    params.require(:user).permit :username, :password, :phone, :time_zone
  end

  def set_user
    @user = User.find params[:id]
  end
end
