# frozen_string_literal: true

RSpec.describe "Model picker auto row" do
  let(:web_dir) { File.expand_path("../../../lib/clacky/web", __dir__) }
  let(:picker)  { File.read(File.join(web_dir, "components/model-picker.js")) }
  let(:styles)  { File.read(File.join(web_dir, "app.css")) }
  let(:i18n)    { File.read(File.join(web_dir, "i18n.js")) }
  let(:sessions) { File.read(File.join(web_dir, "sessions.js")) }

  it "tags the auto alias row with the economy-first label" do
    expect(picker).to include('className = "sib-auto-tag"')
    expect(picker).to include('I18n.t("sib.auto.tag")')
    expect(styles).to include(".sib-auto-tag {")
    expect(i18n).to include('"sib.auto.tag"')
  end

  it "keeps the tag and its hover card on the Settings rows and the variant panel" do
    # Dropdown rows lead with the provider now; the economy-first tag would
    # compete with it. The Settings rows and the in-session variant panel still
    # show it, since their names stand alone.
    expect(picker).to include('if (/^auto$/i.test(modelName || "")) _decorateAutoRow(row, modelName, box);')
    expect(picker).to include('if (/^auto$/i.test(name || "")) _decorateAutoRow(row, name, rightBox);')
    expect(picker).not_to include("_decorateAutoRow(opt, m.model, right);")
  end

  it "leads every row with the provider and keeps the model on the detail line" do
    expect(picker).to include('headText.textContent = providerName || displayName;')
    expect(picker).to include('subLine.className = "sib-model-name-sub";')
    expect(picker).not_to include('className = "sib-model-vision')
    expect(i18n).not_to include('"sib.vision.')
  end

  it "offers a per-row top-up link to the provider console" do
    expect(picker).to include('topUp.className = "sib-topup-btn";')
    expect(picker).to include("topUp.href = m.website_url;")
    expect(styles).to include(".sib-model-option .sib-topup-btn {")
    # Revealed on hover or keyboard focus, so the chip never competes with the
    # model name but stays reachable without a mouse.
    expect(styles).to include(".sib-model-option:hover .sib-topup-btn,")
    expect(styles).to include(".sib-model-option .sib-topup-btn:focus-visible {")
    expect(i18n).to include('"sib.topup"')
  end

  it "drops the dropdown header — the rows carry provider and model" do
    # The list leads with the provider and the current row is marked, so a
    # title plus a "current provider/model" line only cost vertical space.
    expect(picker).not_to include("sib-picker-head")
    expect(picker).not_to include("pickerHeadBits")
    expect(styles).not_to include(".sib-picker-head {")
    expect(i18n).not_to include('"sib.picker.')
  end

  it "paints the default tag with the same tokens in both panels" do
    default_badge = styles[/\.sib-model-option \.model-badge\.default \{.*?\}/m]
    submodel_tag  = styles[/\.sib-submodel-default-tag \{.*?\}/m]

    expect(default_badge).not_to be_nil
    expect(submodel_tag).not_to be_nil
    # One word, one color: the dropdown badge used to be green while the
    # variant panel's tag was grey.
    expect(default_badge).to include("color-mix(in srgb, var(--color-text-secondary) 15%, transparent)")
    expect(default_badge).to include("color: var(--color-text-secondary)")
    expect(submodel_tag).to include("color-mix(in srgb, var(--color-text-secondary) 15%, transparent)")
  end

  it "offers the sub-model switcher on rows other than the current one" do
    expect(picker).to include("onSwitchRowSubModel")
    # Every row falls back to the list the server sends with its model.
    expect(picker).to include(": (m.sub_models || []);")
    expect(picker).to include("if (isCurrentRow || !onSwitchRowSubModel) return onSwitchSubModel(name, displayName);")
    expect(picker).to include("onSwitchRowSubModel(m, name, displayName);")
    # Hidden until the row is reached; the selected row keeps it as a marker.
    expect(styles).to include(".sib-model-option .sib-submodel-toggle {")
    expect(styles).to include(".sib-model-option.submodel-open .sib-submodel-toggle,")
  end

  it "runs the session on the row's model before pinning its variant" do
    expect(sessions).to include(
      "onSwitchRowSubModel: (m, name, displayName) => " \
      "_switchModelAndSubModel(sessionId, m, name, displayName)"
    )

    body = sessions[/async function _switchModelAndSubModel.*?\n  \}/m]
    expect(body).not_to be_nil
    model_call = body.index("`/api/sessions/${sessionId}/model`")
    sub_model_call = body.index("_switchSubModel(sessionId, modelName, displayName)")
    # The sub-model endpoint validates the name against the current card's
    # provider, so the card switch has to come first.
    expect(model_call).to be < sub_model_call
  end
end
