ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "minitest/reporters"
Minitest::Reporters.use!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  include ApplicationHelper

  # Add more helper methods to be used by all tests here...

  # logged_in?ヘルパーはsessionsヘルパーで定義済みなので、名前はis_logged_in?にする
  # logged_in?はテストでも使えてしまうため、テスト用のis_logged_in?をここに定義
  def is_logged_in?
    !session[:user_id].nil?
  end
end
