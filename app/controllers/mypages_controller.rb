class MypagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show edit update posts post]

  def show
    @user = current_user

    @posts = current_user.posts.order(created_at: :desc).includes(:post_images)

    respond_to do |format|
      format.html
      format.json do
        page = params[:page].to_i || 1
        per_page = 12
        offset = (page - 1) * per_page

        @posts = @posts.offset(offset).limit(per_page)
        render json: {
          posts: @posts.as_json(
            include: [
              { user: { methods: :profile_image_url } },
              { post_images: { methods: [:image] } },
              :hashtags,
              :prefecture
            ],
            methods: :created_at_formatted
          ),
          next_page: page + 1,
          last_page: @posts.size < per_page
        }
      end
    end
  end

  def edit
    @user = current_user
  end

  def update
    if @user.update(user_params)
      flash[:success] = 'プロフィールを更新しました'
      redirect_to mypage_url(protocol: 'https'), notice: t('controllers.mypages.update.success')
    else
      flash.now[:error] = "更新に失敗しました: #{@user.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def posts
    @posts = current_user.posts.order(created_at: :desc)
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

  def post
    @post = current_user.posts.includes(:user, :post_images, :hashtags, :prefecture).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to mypage_path, alert: '投稿が見つかりませんでした'
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:username, :uid, :bio, :profile_image_url, :profile_image_url_cache)
  end
end
