class CommentsController < ApplicationController
  before_action :set_comment
  before_action :set_post, only: [:create]

  def create
    @comment = @post.comments.build comment_params
    @comment.creator = current_user

    if @comment.save
      flash[:notice] = 'Your comment was submitted.'
      redirect_to post_path(@post)
    else
      render 'posts/show'
    end
  end

  def vote
    @vote = Vote.create voteable: @comment, creator: current_user, vote: params[:vote]

    if @vote.valid?
      flash[:notice] = 'Your vote has been counted.'
    else
      flash[:error] = 'Your vote was not counted.'
    end

    redirect_to :back
  end

  private

  def comment_params
    params.require(:comment).permit :body
  end

  def set_post
    @post = Post.find params[:post_id]
  end

  def set_comment
    @comment = Comment.find params[:id]
  end
end
