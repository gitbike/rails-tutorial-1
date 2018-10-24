require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test 'password resets' do
    get new_password_reset_path
    assert_template 'password_resets/new'

    # メールアドレスが無効のとき
    post password_resets_path, params: { password_reset: { email: '' } }
    assert_not flash.empty?
    assert_template 'password_resets/new'

    # メールアドレスが有効のとき
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url

    # assignsは、アクションを実行した結果、インスタンス変数に代入されたオブジェクトを取得するためのメソッド
    user = assigns(:user)

    # トークンが有効・メールアドレスが無効のとき
    get edit_password_reset_path(user.reset_token, email: '')
    assert_redirected_to root_url

    # トークンが有効だがアクティベートしていない無効なユーザーのとき
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)

    # メールアドレスが有効・トークンが無効
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url

    # メールアドレスもトークンも有効
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select 'input[name=email][type=hidden][value=?]', user.email

    # パスワード無効・パスワード確認が無効
    patch password_reset_path(user.reset_token), params: { email: user.email,
                                                           user: { password: 'foobaz',
                                                                   password_confirmation: 'awsedrftgy' } }
    assert_select 'div#error_explanation'

    # パスワードが空
    patch password_reset_path(user.reset_token), params: { email: user.email,
                                                           user: { password: '',
                                                                   password_confirmation: '' } }
    assert_select 'div#error_explanation'

    # パスワード・パスワード確認がどちらも正しいとき
    patch password_reset_path(user.reset_token), params: { email: user.email,
                                                           user: { password: 'foobaz',
                                                                   password_confirmation: 'foobaz' } }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
    user.reload
    assert_nil user.reset_digest
  end

  test 'expired token' do
    get new_password_reset_path
    post password_resets_path, params: { password_reset: { email: @user.email } }
    @user = assigns(:user)
    # メールの送信時間を「3時間前」に更新している
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token), params: { email: @user.email,
                                                           user: { password: 'foobar',
                                                                   password_confirmation: 'foobar' } }
    # アクションを実行した結果、302 Found レスポンスが返ってくることの検証
    assert_response :redirect
    # テストの対象をリダイレクト先に切り替える
    follow_redirect!
    # 検査対象の文字列を正規表現で検索できるかを検証 response.bodyはそのページのHTMLを全て返す
    assert_match 'expire', response.body
  end
end
