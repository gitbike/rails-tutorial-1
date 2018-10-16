module SessionsHelper
  # ApplicationControllerがincludeしているので、ここのヘルパーメソッドは全てのビューで使える

  # user.idから一時的なクッキー(ブラウザを閉じると消える)を生成するためにRailsのsessionメソッドを使う
  # sessionメソッドはハッシュと同じように扱える
  def log_in(user)
    session[:user_id] = user.id
  end

  # ブラウザを閉じても消えない永続的な2つのクッキーをIDとremember_tokenから生成する
  def remember(user)
    user.remember
    # cookiesメソッドはハッシュと同じように扱える
    # 攻撃者からユーザーIDを守るため、署名化と暗号化を行いcookies化している
    cookies.permanent.signed[:user_id] = user.id
    # cookiesメソッドは値と有効期限を持つ (有効期限は省略可能)
    # 下記は、 cookies[:remember_token] = { value: user.remember_token, expires: 20.years.from_now.utc } と同義
    cookies.permanent[:remember_token] = user.remember_token

    # cookiesを設定したので、これ以降 User.find_by(id: cookies.signed[:user_id]) で検索できるようになる
    # cookies.signed[:user_id]はcookies化され暗号化されたIDを復号している
  end

  # DBへのアクセスを最初の1回だけにするためのメモイゼーション
  # @current_userかnilを返す
  def current_user
    # 比較ではなく代入を行ない,セッションが存在するか・クッキーが存在するかで分岐
    if (user_id = session[:user_id])  # セッションが存在する場合 (存在しない場合はnil=falseになって分岐する)
      @current_user = User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])  # クッキーが存在する場合
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # 自分のページ以外編集出来ないようににするために作ったメソッド
  # 渡されたユーザー(閲覧中のページのユーザー)がログイン中のユーザーだった場合にtrueを返す
  def current_user?(user)
    user == current_user
  end

  # ログインしているかどうかでヘッダーの項目を変えられるようにするために追加したメソッド
  def logged_in?
    !current_user.nil?
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # deleteだけでも現在のユーザーはnilになるが、安全性を高めたいので、念のため@current_userもnilにしておく
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  # フレンドリーフォワーディングのためのメソッド
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # フレンドリーフォワーディングのためにアクセスしようとしたURLを覚えておく
  def store_location
    # POST PATCH DELETEリクエストで動作しないように、GETリクエストのときだけ動作するようにしておく
    session[:forwarding_url] = request.original_url if request.get?
  end
end
