class PostsController < ApplicationController
  before_action :authenticate_user!
  include PostsHelper
  include PostsJsonBuildable
  include PostCreatable

  POSTS_PER_PAGE = 12

  def index
    @user = current_user
    load_posts_with_filters

    respond_to do |format|
      format.html
      format.json do
        page = params[:slide].to_i
        @posts = Post.with_associations.recent.page(page).per(POSTS_PER_PAGE)

        render json: build_posts_json
      end
    end
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = Post.new
    @prefectures = Prefecture.all
    @post.post_images.build
  end

  def create
    @post = current_user.posts.build(post_params)

    return handle_max_images_exceeded if max_images_exceeded?

    save_post_with_images
  end

  def hashtag
    @user = current_user
    @tag = Hashtag.find_by(name: params[:name])

    if @tag
      load_hashtag_posts
      render_response
    else
      redirect_to posts_url(protocol: 'https'), notice: t('controllers.posts.hashtag.not_found')
    end
  end

  private

  def post_params
    params.require(:post).permit(:prefecture_id, :content, post_images_attributes: [:image])
  end

  def load_posts_with_filters
    @posts = build_base_query
    filter_by_hashtag if params[:name].present?
    apply_pagination
  end

  def build_base_query
    Post.with_associations.recent
  end

  def filter_by_hashtag
    @tag = Hashtag.find_by(name: params[:name])
    @posts = @posts.joins(:hashtags).where(hashtags: { name: params[:name] }) if @tag
  end

  def apply_pagination
    @posts = @posts.page(params[:slide]).per(POSTS_PER_PAGE)
  end

  def load_hashtag_posts
    @posts = @tag.posts.distinct.with_associations.recent.page(params[:slide] || params[:page]).per(POSTS_PER_PAGE)
  end

  def render_response
    respond_to do |format|
      format.html
      format.json { render json: build_posts_json }
    end
  end

  def created_at_formatted
    I18n.l(created_at, format: :long)
  end
end
