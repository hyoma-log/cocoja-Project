class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  validates :terms_agreement, :privacy_agreement, acceptance: { allow_nil: false, accept: '1' }, on: :create
  attr_accessor :terms_agreement, :privacy_agreement

  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :active_relationships, class_name: 'Relationship',
                                 foreign_key: 'follower_id',
                                 dependent: :destroy,
                                 inverse_of: :follower
  has_many :passive_relationships, class_name: 'Relationship',
                                  foreign_key: 'followed_id',
                                  dependent: :destroy,
                                  inverse_of: :followed

  has_many :followings, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  def daily_votes_count
    votes.today.sum(:points)
  end

  def remaining_daily_points
    [0, 5 - daily_votes_count].max
  end

  def can_vote?(points_to_add)
    remaining_daily_points >= points_to_add.to_i
  end

  def voted_today_for?(post)
    votes.exists?(post_id: post.id, voted_on: Time.zone.today)
  end

  def voted_for?(post)
    votes.exists?(post_id: post.id)
  end

  def follow(user)
    return if following?(user)

    active_relationships.create(followed_id: user.id)
  end

  def unfollow(user)
    active_relationships.find_by(followed_id: user.id).destroy
  end

  def following?(user)
    followings.include?(user)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid_from_provider: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]

      if auth.info.image.present?
        user.remote_profile_image_url_url = auth.info.image
      end

      user.skip_confirmation!
      user.terms_agreement = '1'
      user.privacy_agreement = '1'
      user.confirm
    end
  end

  mount_uploader :profile_image_url, ProfileImageUploader

  validates :username, presence: true,
                      length: { minimum: 1, maximum: 20 },
                      uniqueness: true,
                      on: :update

  validates :uid, presence: true,
                 format: { with: /\A[a-zA-Z0-9]+\z/, message: :invalid_format },
                 length: { minimum: 6, maximum: 15 },
                 uniqueness: true,
                 on: :update

  validates :bio, length: { maximum: 160 }, allow_blank: true
end
