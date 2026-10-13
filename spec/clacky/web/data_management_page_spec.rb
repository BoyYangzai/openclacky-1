# frozen_string_literal: true

# The "Data management" page is one sidebar entry opening one page with three
# tabs (archived sessions / recycle bin / backup). These specs pin the wiring that
# used to be three separate panels plus a collapsible sidebar group.
RSpec.describe "Web data management page" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:html)    { File.read(File.join(web_dir, "index.html")) }
  let(:app_js)  { File.read(File.join(web_dir, "app.js")) }
  let(:sidebar_js) { File.read(File.join(web_dir, "components/sidebar.js")) }
  let(:css)     { File.read(File.join(web_dir, "app.css")) }
  let(:i18n_js) { File.read(File.join(web_dir, "i18n.js")) }

  describe "sidebar rail" do
    it "carries a single entry instead of a collapsible group" do
      expect(html.scan('id="data-management-sidebar-item"').size).to eq(1)
      expect(html).not_to include("data-management-group")
      expect(html).not_to include("nav-group")
      expect(html).not_to include("archive-sidebar-item")
      expect(html).not_to include("trash-sidebar-item")
      expect(html).not_to include("backup-sidebar-item")
    end

    it "labels the entry with the data management translation" do
      expect(html).to match(/id="data-management-label"[^>]*data-i18n="sidebar\.dataManagement"/)
    end

    it "routes the entry to the archive tab" do
      expect(sidebar_js).to match(
        /getElementById\("data-management-sidebar-item"\)\.addEventListener\("click", \(\) => Router\.navigate\("archive"\)\)/
      )
      expect(sidebar_js).not_to include("DATA_GROUP")
      expect(sidebar_js).not_to include("syncActive")
    end
  end

  describe "page shell" do
    it "wraps the tab bar and the three tab panels inside one page element" do
      page_open  = html.index('<div id="data-management-panel"')
      tabs       = html.index('id="data-management-tabs"')
      archive    = html.index('<div id="archive-panel"')
      trash      = html.index('<div id="trash-panel"')
      backup     = html.index('<div id="backup-panel"')
      page_close = html.index("<!-- /data-management-panel -->")
      profile    = html.index('<div id="profile-panel"')

      positions = [page_open, tabs, archive, trash, backup, page_close, profile]
      expect(positions).to all(be_a(Integer))
      expect(positions).to eq(positions.sort)
    end

    it "keeps one tab panel per module, all tagged as page views" do
      %w[archive trash backup].each do |name|
        expect(html).to include(%(<div id="#{name}-panel" class="dm-view"))
      end
    end

    it "offers one tab per panel, reusing the panel titles" do
      expect(html.scan("data-dm-tab=").size).to eq(3)
      { "archive" => "archive.title", "trash" => "trash.title", "backup" => "backup.title" }.each do |tab, key|
        expect(html).to match(/<button[^>]*data-dm-tab="#{tab}"[^>]*data-i18n="#{Regexp.escape(key)}"/)
      end
    end

    it "does not repeat the tab labels as in-page headings" do
      expect(html).not_to match(/<h2[^>]*data-i18n="archive\.title"/)
      expect(html).not_to match(/<h2[^>]*data-i18n="trash\.title"/)
      expect(html).not_to match(/<h2[^>]*data-i18n="backup\.title"/)
    end

    it "describes the backup destination once instead of twice" do
      # The panel used to carry a subtitle listing the same directory contents as
      # the Auto Backup section below it, so the tab opened with the same sentence
      # twice in a row.
      panel = html[html.index('<div id="backup-panel"')...html.index('<div id="backup-content"')]
      expect(panel).not_to include("channels-page-subtitle")
      expect(html).not_to include('data-i18n="backup.subtitle"')
      expect(i18n_js).not_to include('"backup.subtitle"')
      expect(html.scan('data-i18n="settings.backup.desc"').size).to eq(1)
    end

    it "shows a page title and description above the tab bar" do
      header   = html.index('id="data-management-header"')
      title    = html.index('data-i18n="dataManagement.title"')
      subtitle = html.index('data-i18n="dataManagement.subtitle"')
      tabs     = html.index('id="data-management-tabs"')

      positions = [header, title, subtitle, tabs]
      expect(positions).to all(be_a(Integer))
      expect(positions).to eq(positions.sort)
      expect(html).to match(/<h2[^>]*data-i18n="dataManagement\.title"/)
      expect(html).to match(/<p[^>]*data-i18n="dataManagement\.subtitle"/)
    end
  end

  describe "router" do
    it "registers the page shell as a panel" do
      expect(app_js).to match(/const PANELS = \[[^\]]*"data-management-panel"/m)
    end

    it "highlights the single rail entry for all three views" do
      %w[trash archive backup].each do |view|
        expect(app_js).to match(/^\s+#{view}:\s+"data-management-sidebar-item",$/)
      end
    end

    it "shows the page and selects the matching tab per route" do
      %w[archive trash backup].each do |view|
        expect(app_js).to match(
          /case "#{view}":\n\s+_setHash\("#{view}"\);\n\s+_showDataManagementTab\("#{view}"\);/
        )
      end
    end

    it "toggles tab panels and tab buttons from the tab list" do
      expect(app_js).to match(/const DATA_MANAGEMENT_TABS = \["archive", "trash", "backup"\];/)
      expect(app_js).to match(/page\.style\.display = "flex";/)
      expect(app_js).to match(/panel\.style\.display = name === tab \? "flex" : "none";/)
      expect(app_js).to match(/btn\.classList\.toggle\("active", name === tab\);/)
    end

    it "routes a tab click through the router" do
      expect(app_js).to match(/const tab = e\.target\.closest\("\[data-dm-tab\]"\);/)
      expect(app_js).to match(/if \(tab\) Router\.navigate\(tab\.dataset\.dmTab\);/)
    end

    it "no longer tracks sidebar group state" do
      expect(app_js).not_to include("_syncSidebarGroups")
      expect(app_js).not_to include("nav-group")
    end
  end

  describe "styles" do
    it "lays the page out as a full-height column of tab bodies" do
      expect(css).to include("#data-management-panel {")
      expect(css).to match(/#data-management-panel > \.dm-view \{\n\s+min-height: 0;/)
    end

    it "drops the retired sidebar group styles" do
      expect(css).not_to include(".nav-group")
    end

    it "pads the page header like the tab bodies" do
      expect(css).to match(/#data-management-header \{\n\s+padding: 1\.75rem 2\.25rem 0;/)
      expect(css).to match(/#data-management-header \{ padding: 1rem 1rem 0; \}/)
    end

    it "insets the tab bar so its underline stops at the content column" do
      expect(css).to match(/#data-management-tabs \{\n\s+margin: 1\.25rem 2\.25rem 0;/)
      expect(css).to match(/#data-management-tabs \{ margin: 1rem 1rem 0; \}/)
      expect(css).not_to match(/#data-management-tabs \{\n\s+padding:/)
    end
  end

  describe "translations" do
    it "translates the page header and every tab label in both locales" do
      %w[archive.title trash.title backup.title sidebar.dataManagement
         dataManagement.title dataManagement.subtitle].each do |key|
        expect(i18n_js.scan(%("#{key}":)).size).to eq(2)
      end
    end

    it "opens the recycle bin straight into the tab bar, with no file-only blurb" do
      # The panel used to introduce itself as a list of agent files, which no
      # longer describes a page that opens on its sessions tab.
      panel = html[html.index('<div id="trash-panel"')...html.index("<!-- ── BACKUP PANEL")]
      expect(panel).not_to include("channels-page-subtitle")
      expect(html).not_to include('data-i18n="trash.subtitle"')
      expect(i18n_js).not_to include('"trash.subtitle"')
      expect(i18n_js).not_to include("Recall them back")
    end

    it "points the memory delete confirmation at the recycle bin" do
      # The dialog named "文件召回 / File Recall", a page that no longer exists.
      expect(i18n_js).to include("会先放入「回收站」，仍可从那里恢复。")
      expect(i18n_js).to include("It will be moved to the Recycle Bin")
      expect(i18n_js).not_to include("文件召回")
      expect(i18n_js).not_to include("File Recall")
    end

    it "now calls the recycle bin tab 回收站 in Chinese" do
      # "数据回收" was a literal translation that no Chinese product uses; 回收站 is
      # what the users of a file manager already look for.
      expect(i18n_js).to match(/"trash\.title":\s+"回收站",/)
      expect(i18n_js).not_to include("数据回收")
    end
  end
end
