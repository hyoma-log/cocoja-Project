class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show following followers posts]

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.order(created_at: :desc).includes(:post_images)
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t('controllers.users.not_found')
    redirect_to user_path
  end

  def following
    @title = t('controllers.users.following.title')
    @users = @user.followings.page(params[:page])
    render 'show_follow'
  end

  def followers
    @title = t('controllers.users.followers.title')
    @users = @user.followers.page(params[:page])
    render 'show_follow'
  end

  def posts
    @posts = @user.posts.order(created_at: :desc)
                  .includes(:user, :post_images, :hashtags, :prefecture)

    respond_to do |format|
      format.html
      format.json do
        page = params[:page].to_i || 1
        per_page = 10
        offset = (page - 1) * per_page

        paginated_posts = @posts.offset(offset).limit(per_page)
        render json: {
          posts: render_to_string(partial: 'posts/post', collection: paginated_posts, formats: [:html]),
          next_page: page + 1,
          last_page: paginated_posts.size < per_page
        }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t('controllers.users.not_found')
    redirect_to user_path
  end
end
