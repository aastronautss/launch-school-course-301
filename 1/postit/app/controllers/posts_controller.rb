class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def show
    @post = Post.find params[:id]

    if @post.nil?
      redirect_to action: :index
    end
  end

  def new

  end

  def create

  end

  def edit

  end

  def update

  end
end
