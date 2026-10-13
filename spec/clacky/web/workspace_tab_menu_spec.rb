# frozen_string_literal: true

require "open3"

RSpec.describe "Web workspace tab context menu" do
  it "offers closing and the file actions on a right-clicked file tab" do
    script = File.expand_path("../../support/workspace_tab_menu_test.js", __dir__)
    output, status = Open3.capture2e("node", script)
    expect(status.success?).to be(true), output
  end
end
