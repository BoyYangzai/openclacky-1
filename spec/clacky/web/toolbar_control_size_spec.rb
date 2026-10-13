# frozen_string_literal: true

# The archive and recycle-bin toolbars used to run on 28px controls with 12px
# labels, which read as a thin strip next to the rest of the page. Every control
# in those rows now shares one taller size — this pins that size and the pieces
# that have to follow it (search field, chip labels, summary line).
RSpec.describe "Toolbar control sizes" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:css)     { File.read(File.join(web_dir, "app.css")) }

  # The one rule that gives the filter dropdowns and the bulk action buttons
  # their shared shape.
  def strip_rule
    body = css[%r{\.trash-filter-project-wrap,\n\.btn-trash-action \{\n(.*?)^\}}m, 1]
    raise "shared toolbar control rule not found" unless body

    body
  end

  # Body of a single-selector rule, e.g. rule(".trash-summary").
  def rule(selector)
    body = css[/^#{Regexp.escape(selector)} \{\n(.*?)^\}/m, 1]
    raise "#{selector} rule not found" unless body

    body
  end

  it "gives every control in the strip the same taller shape" do
    strip = strip_rule
    expect(strip).to include("height: 2.125rem;")
    expect(strip).to include("font-size: 0.8125rem;")
    expect(strip).to include("border-radius: 8px;")
    expect(strip).to include("padding: 0 0.75rem;")
  end

  it "sizes the search field to the strip, label included" do
    strip  = strip_rule
    height = strip[/height: ([^;]+);/, 1]
    radius = strip[/border-radius: ([^;]+);/, 1]
    font   = strip[/font-size: ([^;]+);/, 1]

    search = rule(".archive-search-wrap")
    expect(search).to include("height: #{height};")
    expect(search).to include("border-radius: #{radius};")
    expect(rule(".archive-search-input")).to include("font-size: #{font};")
  end

  it "keeps the dropdown chip label and the summary line on the strip's type scale" do
    font = strip_rule[/font-size: ([^;]+);/, 1]

    expect(rule(".trash-filter-project-wrap .custom-select-trigger--bare")).to include("font-size: #{font};")
    expect(rule(".trash-summary")).to include("font-size: #{font};")
  end

  it "gives the search field its own line once the toolbar wraps" do
    expect(css).to match(
      /^\s+\.archive-search-wrap \{\n\s+flex-basis: 100%;\n\s+max-width: none;\n\s+\}/
    )
  end
end
