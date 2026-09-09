require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in }

  test "should get edit" do
    get settings_edit_url
    assert_response :success
  end

  test "should update" do
    patch settings_path, params: { setting: { prompt: "テスト", timezone: "Tokyo" } }
    assert_redirected_to settings_url
    assert_equal "テスト", Setting.instance.prompt
  end
end
