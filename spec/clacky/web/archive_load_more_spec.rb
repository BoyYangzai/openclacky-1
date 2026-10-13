# frozen_string_literal: true

# The archived-session list is paged, and its "Load more" button used to borrow
# the toolbar chip style, which left a 28px pill floating in the middle of the
# page. It now matches the load-more rows on the session list and extensions page.
RSpec.describe "Archive load-more button" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:html)    { File.read(File.join(web_dir, "index.html")) }
  let(:css)     { File.read(File.join(web_dir, "app.css")) }
  let(:view_js) { File.read(File.join(web_dir, "features/archive/view.js")) }
  let(:store_js) { File.read(File.join(web_dir, "features/archive/store.js")) }
  let(:i18n_js) { File.read(File.join(web_dir, "i18n.js")) }

  def rule(selector)
    match = css[/^#{Regexp.escape(selector)} \{\n(.*?)^\}/m, 1]
    raise "#{selector} rule not found" unless match

    match
  end

  it "drops the toolbar chip classes from the markup" do
    expect(html).to match(/<button id="btn-archive-load-more" style="display:none" data-i18n="archive.loadMore">Load more<\/button>/)
    expect(html).not_to match(/<button id="btn-archive-load-more"[^>]*btn-trash-action/)
  end

  it "is a full-width row button, like the other load-more buttons" do
    own    = rule("#btn-archive-load-more")
    shared = rule(".extensions-load-more")

    %w[width display padding border-radius font-size].each do |prop|
      expect(own).to include(shared[/^\s*#{prop}:.*$/])
    end
    expect(own).to include("display: block;")
    expect(own).not_to include("align-self")
  end

  it "keeps the hover and disabled states" do
    expect(css).to match(/#btn-archive-load-more:hover:not\(:disabled\) \{/)
    expect(css).to match(/#btn-archive-load-more:disabled \{/)
  end

  it "shows progress on the button instead of blanking the list" do
    expect(store_js).to match(/_emit\("archive:loading", \{ append: opts\.reset === false \}\)/)
    expect(view_js).to match(/if \(payload && payload\.append\) _setMoreLoading\(true\);\n\s+else _renderSkeleton\(\);/)
    expect(view_js).to match(/btn\.textContent = loading \? _t\("archive\.loadingMore"\) : _t\("archive\.loadMore"\);/)
    expect(view_js).to match(/btn\.disabled = loading;/)
  end

  it "clears the loading state once the page lands or the load fails" do
    expect(view_js).to match(/if \(btnMore\) \{\n\s+btnMore\.style\.display = Archive\.state\.hasMore \? "" : "none";\n\s+_setMoreLoading\(false\);/)
    expect(view_js).to match(/function _renderError\(message\) \{[\s\S]*?_setMoreLoading\(false\);/)
  end

  it "translates both labels in both locales" do
    %w[archive.loadMore archive.loadingMore].each do |key|
      expect(i18n_js.scan(%("#{key}":)).size).to eq(2)
    end
    expect(i18n_js).to match(/"archive\.loadingMore":\s+"加载中…",/)
  end
end
