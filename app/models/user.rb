class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  # Relationshipモデルからactive_relationships表を作っている
  has_many :active_relationships, class_name: 'Relationship', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_relationships, class_name: 'Relationship', foreign_key: 'followed_id', dependent: :destroy
  # user.followedsは英語として不自然なので、user.followingに書き換えている.配列user.followingはrelationships表のfollowed_idの集合である
  has_many :following, through: :active_relationships, source: :followed
  # sourceパラメータを省略してもRailsがfollower_idを探してくれる(上のコードとの類似性を示すために残している).以下のコードによりuser.follersメソッドが使用可能になる
  has_many :followers, through: :passive_relationships, source: :follower

  
  # rememberメソッドがアクセスできるようにするため、remember_tokenをアクセサに設定
  # activation_tokenはDBに保存されない使い捨てのものなので、ここに設定してcreate_activation_digestがアクセスできるようにする
  attr_accessor :remember_token, :activation_token, :reset_token

  before_save :downcase_email
  before_create :create_activation_digest

  validates :name, { presence: true, length: { maximum: 50 } }

  VALID_EMAIL_REGEX =  /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, { presence: true,
                      length: { maximum: 255 },
                      format: { with: VALID_EMAIL_REGEX },
                      uniqueness: { case_sensitive: false } }

  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  class << self
    # 文字列をハッシュ化するためのメソッド
    def digest(unencrypted_password)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
      BCrypt::Password.create(unencrypted_password, cost: cost)
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  # セッションを永続化するため、DBに登録する
  def remember
    # ログインするたびに新しいトークンを発行する(攻撃者がクッキーを奪い取っても、本物のユーザーがログアウトすると攻撃者はログインできなくなるようにするため)
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  # 第一引数はremember_digestとactivation_digestに対応できるように抽象化している
  def authenticated?(attribute, token)
    # 右辺は self.send(:attribute_digest) と同義。モデル内なのでselfは省略可能(Rubyでは、メソッド内でレシーバを省略してメソッドを呼び出すと、暗黙的にselfがレシーバとなる。selfはそのメソッドが属しているインスタンス)
    digest = send("#{attribute}_digest")
    # 複数ブラウザでログアウトしたときにエラーにならないようにするため、片方のブラウザでログアウトしている時(remember_digestがnilのとき)はBCryptを実行しないようにする
    return false if digest.nil?
    # remember_tokenはこの場限りのローカル変数であり、オブジェクトのアクセサである:remember_tokenとは無関係
    # remember_digestはself.remember_digestと同じでUserオブジェクトの属性。DBのremember_digestカラムに対応
    BCrypt::Password.new(digest).is_password?(token)
  end

  # ログアウトするためのメソッド
  def forget
    update_attribute(:remember_digest, nil)
  end

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
    # Userモデルの中なのでself.update_attributeのselfを省略できる
    # update_attribute(:activated, true)
    # update_attribute(:activated_at, Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    # データベースへの問い合わせを2回から1回にするために、update_attributeではなくupdate_columnsを使っている
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
    # update_attribute(:reset_digest, User.digest(reset_token))
    # update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def feed
    # 高速化のため、following_idsをDBに計算させる
    following_ids = 'SELECT followed_id
                     FROM relationships
                     WHERE follower_id = :user_id'
    Micropost.where("user_id IN (#{following_ids})
                    OR user_id = :user_id", user_id: id)

    # 以下のコードはfollowing_idsをRailsに計算させているので遅い
    # Micropost.where('user_id IN (?) OR user_id = ?', following_ids, id)

    # 14章で上書き
    # SQLインジェクション対策 ?があることでidがエスケープされる(プリペアドステートメント)
    # Micropost.where('user_id = ?', id)
  end

  # モデルの中ではselfは省略可能
  def follow(other_user)
    following << other_user
  end

  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  def following?(other_user)
    following.include?(other_user)
  end

  # Userモデルでしか使わないメソッドは外部に公開する必要がないため、privateにしている
  private

    def downcase_email
      # email.downcase! は self.email = self.email.downcaseと同じ意味(右辺のselfは省略可能)
      # メソッド内でメソッド呼び出しをすると、レシーバは暗黙的にselfになる
      email.downcase!
    end

    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
