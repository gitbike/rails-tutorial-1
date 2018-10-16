class User < ApplicationRecord
  # rememberメソッドがアクセスできるようにするため
  attr_accessor :remember_token

  before_save { email.downcase! }
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
  def authenticated?(remember_token)
    # 複数ブラウザでログアウトしたときにエラーにならないようにするため、片方のブラウザでログアウトしている時(remember_digestがnilのとき)はBCryptを実行しないようにする
    return false if remember_digest.nil?
    # remember_tokenはこの場限りのローカル変数でオブジェクトのアクセサであるremember_tokenとは無関係
    # remember_digestはself.remember_digestと同じでUserオブジェクトの属性。DBのremember_digestカラムに対応
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ログアウトするためのメソッド
  def forget
    update_attribute(:remember_digest, nil)
  end
end
