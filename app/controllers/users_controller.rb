class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: :destroy

  def index
    @users = User.where(activated: true).paginate(page: params[:page])

    # 11章の演習で上書きされたコード
    # @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])

    # &&だとandよりも優先順位が高く、正常に動作しないのでandを使っている(11章の演習)。 また、redirect_toメソッドはand returnで明示的に終了させないと下のメソッドも次々に実行されてしまう
    redirect_to root_url and return unless @user.activated?

    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = 'Please check your email to activate your account.'
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = 'Profile updated'
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = 'User deleted.'
    redirect_to users_url
  end

  def following
    @title = 'Following'
    @user = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = 'Followers'
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end


  # Web経由で外部のユーザーが利用できないようにprivate化する
  private
    # マスアサインメント脆弱性対策として、User.new(params[:user])はデフォルトで使用禁止になっている
    # 適切に初期化されたparamsハッシュ(Strong Parameters)をcreateアクションやupdateアクションに返すためのメソッド
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end



    # editとupdateアクションで自分のページ以外編集できないようにするためのbeforeフィルター
    def correct_user
      @user = User.find(params[:id])
      redirect_to root_url unless current_user?(@user)
    end

    # adminでなければdestroyアクションを実行できないようにするためのbeforeフィルター
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
end
