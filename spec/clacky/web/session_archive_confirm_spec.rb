# frozen_string_literal: true

RSpec.describe "Session archive confirmation" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:sessions) { File.read(File.join(web_dir, "sessions.js")) }
  let(:i18n) { File.read(File.join(web_dir, "i18n.js")) }

  def set_archived_body
    body = sessions[/async setArchived\(sessionId, archived\) \{(.*?)\n    \},/m, 1]
    raise "setArchived not found in sessions.js" unless body

    body
  end

  it "asks for confirmation before archiving and aborts when declined" do
    body = set_archived_body

    expect(body).to match(
      /if \(archived\) \{\s*const confirmed = await Modal\.confirm\(I18n\.t\("archive\.confirmArchive", \{ name \}\)\);\s*if \(!confirmed\) return false;/
    )
    expect(body.index("Modal.confirm")).to be < body.index("Archive.archiveSession")
  end

  it "skips the confirmation when restoring an archived chat" do
    body = set_archived_body

    expect(body).not_to match(/if \(!archived\) \{\s*const confirmed = await Modal\.confirm/)
    expect(body).to include("await Archive.unarchive(session)")
  end

  it "translates the confirmation message in both locales" do
    expect(i18n.scan('"archive.confirmArchive"').size).to eq(2)
    expect(i18n).to include('Archive \"{{name}}\"?')
    expect(i18n).to include("归档「{{name}}」？")
  end

  describe "archived sessions wording" do
    let(:html) { File.read(File.join(web_dir, "index.html")) }

    it "calls them sessions, not chats, in every archive string" do
      %w[title searchPlaceholder empty noMatch confirmArchive confirmDeleteAll].each do |key|
        values = i18n.scan(/^\s+"archive\.#{key}":\s+(.+)$/).flatten
        expect(values.size).to eq(2)
        values.each { |value| expect(value).not_to match(/chats?|聊天/) }
      end
    end

    it "keeps the page copy and placeholders in sync with the translations" do
      %w[dataManagement.subtitle archive.title archive.searchPlaceholder].each do |key|
        values = i18n.scan(/^\s+"#{Regexp.escape(key)}":\s+(.+)$/).flatten
        expect(values.size).to eq(2)
        values.each { |value| expect(value).not_to match(/chats?|聊天/) }
      end

      expect(html).not_to match(/Archived chats|archived chats|Search archived chats/)
    end

    it "has no blurb of its own — the page header already explains the page" do
      panel = html[/<div id="archive-panel".*?<div id="archive-list">/m]

      expect(panel).not_to include("channels-page-subtitle")
      expect(i18n).not_to include("archive.subtitle")
    end

    it "keeps the delete-all action in the toolbar row, next to the count" do
      toolbar = html[/<div id="archive-panel".*?(<div class="trash-toolbar">.*?)<div id="archive-list">/m, 1]

      expect(toolbar).to include('id="archive-summary"')
      expect(toolbar).to include('id="btn-archive-delete-all"')
      expect(toolbar.index('id="archive-summary"')).to be < toolbar.index('id="btn-archive-delete-all"')
    end
  end

  describe "archived sessions toolbar" do
    let(:css) { File.read(File.join(web_dir, "app.css")) }

    def rule(selector)
      body = css[/^#{Regexp.escape(selector)} \{(.*?)^\}/m, 1]
      raise "#{selector} not found in app.css" unless body

      body
    end

    it "caps the search field so it cannot stretch across the toolbar" do
      search = rule(".archive-search-wrap")

      expect(search).to include("flex: 1;")
      expect(search).to match(/max-width: 18rem;/)
    end

    it "gives the search field the same height as the filters beside it" do
      # The literal height lives in toolbar_control_size_spec; this only checks
      # the field keeps following whatever the filter controls use.
      shared_height = css[/^\.trash-filter-project-wrap,\s*$.*?height:\s*([^;]+);/m, 1]

      expect(rule(".archive-search-wrap")).to include("height: #{shared_height.strip};")
    end

    it "anchors the count to the right edge without splitting the free space" do
      summary = rule("#archive-summary")

      # Two auto margins would split the leftover width into two gaps; the search
      # field already claims the only flexible slot.
      expect(summary).to include("margin-left: auto;")
      expect(summary).to include("margin-right: 0;")
    end
  end
end
