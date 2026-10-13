# frozen_string_literal: true

RSpec.describe "Session actions menu layout" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:sessions) { File.read(File.join(web_dir, "sessions.js")) }
  let(:styles) { File.read(File.join(web_dir, "app.css")) }

  # The actions menu markup, cut out of _showActionsMenu's template literal.
  def menu_markup
    start = sessions.index('menu.className = "session-actions-menu";')
    raise "actions menu template not found" unless start

    tail = sessions[start..-1]
    tail[/menu\.innerHTML = `(.*?)`;/m, 1]
  end

  it "separates the last group with a divider placed above Archive" do
    markup = menu_markup

    move_to_project = markup.index('data-action="moveToProject"')
    divider = markup.index('class="session-actions-menu-divider"')
    archive = markup.index("${archiveItemHtml}")
    delete = markup.index('data-action="delete"')

    expect([move_to_project, divider, archive, delete]).to all(be_a(Integer))
    expect(divider).to be > move_to_project
    expect(archive).to be > divider
    expect(delete).to be > archive
  end

  it "draws a single divider and keeps the danger styling on Delete" do
    markup = menu_markup

    expect(markup.scan("session-actions-menu-divider").size).to eq(1)
    expect(markup).to include(
      'class="session-actions-menu-item session-actions-menu-item--danger" data-action="delete"'
    )
  end

  it "styles the divider explicitly instead of the danger item's top line" do
    expect(styles).to match(
      /\.session-actions-menu-divider \{.*?height: 1px;.*?background: var\(--color-border-secondary\);/m
    )
    expect(styles).not_to include(".session-actions-menu-item--danger::before")
    expect(styles).not_to match(/\.session-actions-menu-item--danger \{.*?margin-top/m)
  end
end
