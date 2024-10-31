require "test_helper"

class RoadmapControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get roadmap_create_url
    assert_response :success
  end
end
