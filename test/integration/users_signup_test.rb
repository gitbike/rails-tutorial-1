require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  # 複数のテストを並行して行うために、配列deliveriesは内容を初期化するためのメソッド
  def setup
    ActionMailer::Base.deliveries.clear
  end

  test 'invalid signup information' do
    get signup_path
    assert_no_difference 'User.count' do
      post signup_path, params: { user: { name: '',
                                          email: 'user@invalid',
                                          password: 'foo',
                                          password_confirmation: 'bar' } }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.alert'
    assert_select 'div.alert-danger'
    assert_select 'form[action="/signup"]'
  end

  test 'valid signup information with account activation' do
    get signup_path
    # 第2引数の「1」 はブロック内のコードを実行する前と後でデータベースのレコードが1増えていることを意味する
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name: 'Example User',
                                         email: 'user@example.com',
                                         password: 'password',
                                         password_confirmation: 'password' } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size

    # assignsメソッドはusersコントローラのインスタンス変数@userにアクセスできるようにしている
    user = assigns(:user)
    assert_not user.activated?
    # 有効化していない状態でのログイン
    log_in_as(user)
    assert_not is_logged_in?

    # 有効化トークンが無効の場合
    get edit_account_activation_path('invalid token', email: user.email)
    assert_not is_logged_in?

    # トークンは正しいがメールが無効の場合
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not is_logged_in?

    # 有効化トークンが正しい場合
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!

    # assert_select 'div.alert'
    # assert_select 'div.alert-success'
    # assert_not flash.empty?
    assert_template 'users/show'
    assert is_logged_in?
  end
end
