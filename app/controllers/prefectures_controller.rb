class PrefecturesController < ApplicationController
  def show
    @prefecture = Prefecture.find(params[:id])

    @posts = @prefecture.posts.joins(:votes)
                        .select('posts.*, SUM(votes.points) as total_points_sum')
                        .group('posts.id')
                        .having('SUM(votes.points) > 0')
                        .order('total_points_sum DESC')

    @posts_count = @posts.length
    @total_points = @prefecture.posts.joins(:votes).sum('votes.points')
  end

  def posts
    @prefecture = Prefecture.find(params[:id])
    @posts = @prefecture.posts
                        .includes(:user, :hashtags, :post_images)
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(10)

    @posts_count = @prefecture.posts.count

    @page_title = "#{@prefecture.name}の投稿"

    respond_to do |format|
      format.html do
        @total_points = @prefecture.posts.left_joins(:votes).sum('COALESCE(votes.points, 0)')
      end

      format.json do
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
          next_page: @posts.next_page
        }
      end
    end
  end
end
