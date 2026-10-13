# frozen_string_literal: true

# The archive toolbar has two dropdown chips: the project picker (folder glyph)
# and the type picker. The type picker used to carry a funnel glyph that read as
# a smudge at 13px, and both chips only opened when the text itself was clicked.
RSpec.describe "Archive filter chips" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:html)    { File.read(File.join(web_dir, "index.html")) }
  let(:css)     { File.read(File.join(web_dir, "app.css")) }

  # The markup of one chip, located by the id of the select it wraps.
  def chip(select_id)
    match = html[%r{<div class="trash-filter-project-wrap"[^>]*>.*?<div class="custom-select-wrapper" id="#{select_id}">}m]
    raise "#{select_id} chip not found" unless match

    match
  end

  it "labels the type picker with a tag glyph instead of the funnel" do
    expect(chip("archive-filter-type")).to include('<path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.83z"/>')
    expect(chip("archive-filter-type")).to include('<line x1="7" y1="7" x2="7.01" y2="7"/>')
    expect(html).not_to include("M22 3H2l8.46 10.5")
  end

  it "keeps the folder glyph on both project pickers" do
    folder = '<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>'
    expect(chip("archive-filter-project")).to include(folder)
    expect(chip("trash-filter-project")).to include(folder)
    # Two pickers per toolbar: the archive and recycle bin pages each carry a
    # project picker and a type picker, and they share this icon class.
    expect(html.scan('class="trash-filter-project-icon"').size).to eq(4)
  end

  it "stretches the trigger's hit area across the whole chip" do
    # The dropdown wrapper is `position: static`, so the trigger's ::after is
    # laid out against the chip and `inset: 0` covers its icon and padding.
    expect(css).to match(
      /\.trash-filter-project-wrap \.custom-select-trigger::after \{\n\s+content: "";\n\s+position: absolute;\n\s+inset: 0;\n\}/
    )
    expect(css.scan(/\.trash-filter-project-wrap \.custom-select-trigger::after/).size).to eq(1)
    expect(css).to match(/\.trash-filter-project-wrap \{\n\s+position: relative;\n\}/)
  end
end
