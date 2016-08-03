class CommentsController < ApplicationController
  def create
    @post = Post.find params[:post_id]
    @comment = @post.comments.new params.require(:comment).permit(:body)

    if @comment.save
      flash[:notice] = 'Your comment was submitted.'
      redirect_to post_path(@post)
    else
      render 'posts/show'
    end
  end
end
