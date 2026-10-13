# frozen_string_literal: true

# Unarchiving only moves a chat back to the sidebar: the row vanishes from the
# archive page, so the success toast carries a shortcut to the restored chat —
# the same action button the recycle bin shows after restoring a session.
RSpec.describe "Unarchive toast shortcut" do
  let(:web_dir)     { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:view_js)     { File.read(File.join(web_dir, "features/archive/view.js")) }
  let(:sessions_js) { File.read(File.join(web_dir, "sessions.js")) }
  let(:i18n_js)     { File.read(File.join(web_dir, "i18n.js")) }

  def unarchive_body
    body = view_js[/async function _unarchive\(session\) \{(.*?)\n  \}/m, 1]
    raise "_unarchive not found in archive/view.js" unless body

    body.gsub(/\s+/, " ")
  end

  def set_archived_body
    body = sessions_js[/async setArchived\(sessionId, archived\) \{(.*?)\n    \},/m, 1]
    raise "setArchived not found in sessions.js" unless body

    body.gsub(/\s+/, " ")
  end

  it "opens the restored chat from the archive page toast" do
    body = unarchive_body

    expect(body).to include("const id = session.id || session.session_id;")
    expect(body).to include(
      'Modal.toast(I18n.t("archive.unarchived", { name: session.name || "" }), "success", ' \
      'id ? { action: { label: _t("archive.unarchivedAction"), onClick: () => Sessions.select(id) } } : {});'
    )
    # A row without an id could not be opened anyway, so no button is rendered.
    expect(body.index("const id =")).to be < body.index('Modal.toast(I18n.t("archive.unarchived"')
  end

  it "opens the restored chat from the sidebar menus and the undo shortcut" do
    body = set_archived_body

    expect(body).to include(
      'Modal.toast(I18n.t("archive.unarchived", { name }), "success", { action: { ' \
      'label: I18n.t("archive.unarchivedAction"), onClick: () => Sessions.select(sessionId), }, });'
    )
    expect(body.scan('label: I18n.t("archive.unarchivedAction")').size).to eq(2)
  end

  it "labels every restored toast with the recycle bin wording" do
    expect(i18n_js.scan('"archive.unarchivedAction"').size).to eq(2)
    expect(i18n_js).to match(/"archive\.unarchivedAction":\s+"Open",/)
    expect(i18n_js).to match(/"archive\.unarchivedAction":\s+"去查看",/)

    labels = lambda do |key|
      i18n_js.scan(/^\s+"#{Regexp.escape(key)}":\s+"([^"]+)",$/).flatten
    end
    expect(labels.call("archive.unarchivedAction")).to eq(labels.call("trash.sessionRestoreOkAction"))
  end
end
