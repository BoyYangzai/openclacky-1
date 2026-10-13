# frozen_string_literal: true

# The recycle bin's session list used to filter by source with a row of chips
# (All / Regular / Scheduled). Those are now one dropdown that offers exactly
# the four types the archive page filters by, so the two toolbars agree.
RSpec.describe "Recycle bin source filter" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:html)    { File.read(File.join(web_dir, "index.html")) }
  let(:view_js) { File.read(File.join(web_dir, "features/trash/view.js")) }
  let(:store_js) { File.read(File.join(web_dir, "features/trash/store.js")) }
  let(:css)     { File.read(File.join(web_dir, "app.css")) }
  let(:i18n_js) { File.read(File.join(web_dir, "i18n.js")) }

  def collapsed(text)
    text.gsub(/\s+/, " ")
  end

  # The session filter bar, cut out of index.html.
  def filter_bar
    match = html[%r{<div class="trash-filter-bar".*?<span class="trash-summary"}m]
    raise "trash filter bar not found" unless match

    collapsed(match)
  end

  it "renders the source filter as a dropdown, not chips" do
    bar = filter_bar

    expect(html).not_to include("trash-filter-chip")
    expect(bar).to include('<div class="custom-select-wrapper" id="trash-filter-source">')
    expect(bar).to match(/id="trash-filter-source">\s*<div class="custom-select-trigger custom-select-trigger--bare"/)
    expect(bar).to include('<span class="custom-select-value placeholder" data-i18n="trash.filterAllTypes">All types</span>')
    expect(bar).to include('<div class="custom-select-dropdown"></div>')
  end

  it "gives the dropdown the same tag icon the archived-sessions type filter uses" do
    bar = filter_bar

    expect(bar.scan('class="trash-filter-project-icon"').size).to eq(2)
    # Tag glyph — the source filter is a "what kind of session" filter, like the
    # type filter on the archive page.
    expect(bar).to include("M20.59 13.41l-7.17 7.17")
  end

  it "builds the same four options the archive type filter offers" do
    build = view_js[/function _buildSourceOptions.*?\n  \}/m]
    raise "source option builder not found" unless build

    # The empty value is "every type", which keeps the trigger in the
    # placeholder state the archive filters use.
    expect(build).to include('{ value: "",                   label: _t("trash.filterAllTypes") }')
    expect(build).to include('{ value: Trash.SOURCES.MANUAL, label: _t("trash.filterManual") }')
    expect(build).to include('{ value: Trash.SOURCES.CRON,   label: _t("trash.filterCron") }')
    expect(build).to include('{ value: Trash.SOURCES.CHANNEL, label: _t("trash.filterChannel") }')
  end

  it "filters the list by the archive page's source predicate" do
    expect(store_js).to match(/SOURCES = Object\.freeze\(\{ ALL: "all", CRON: "cron", MANUAL: "manual", CHANNEL: "channel" \}\)/)
    expect(store_js).to include("list.filter(s => (s.source || SOURCES.MANUAL) === _filterSource);")
  end

  it "routes selection through the store and restores the current filter" do
    wiring = collapsed(view_js)
    select = wiring[/const sourceWrap = \$\("trash-filter-source"\);.{0,420}/m]
    raise "source select wiring not found" unless select

    expect(select).to include('window.CustomSelect.init(')
    expect(select).to include("onSelect: (value) => Trash.setFilterSource(value || Trash.SOURCES.ALL)")
    expect(select).to include("_syncSourceSelect();")
    expect(wiring).to include("ctl.setValue(current === Trash.SOURCES.ALL ? \"\" : current);")
    expect(view_js).not_to include(".trash-filter-chip")
  end

  it "keeps the retired chip styles out of the stylesheet" do
    expect(css).not_to include(".trash-filter-chip")
    expect(css).to match(/\.trash-filter-project-wrap,\n\.btn-trash-action \{/)
  end

  it "labels the four types with the archived-sessions wording" do
    expect(i18n_js).not_to include('"trash.filterAll":')

    labels = lambda do |key|
      i18n_js.scan(/^\s+"#{Regexp.escape(key)}":\s+"([^"]+)",$/).flatten
    end

    {
      "trash.filterAllTypes" => "archive.filterAllTypes",
      "trash.filterManual"   => "archive.filterRegular",
      "trash.filterCron"     => "archive.filterCron",
      "trash.filterChannel"  => "archive.filterChannel",
    }.each do |trash_key, archive_key|
      expect(labels.call(trash_key).size).to eq(2)
      expect(labels.call(trash_key)).to eq(labels.call(archive_key))
    end
  end
end
