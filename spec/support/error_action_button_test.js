"use strict";

// Regression harness for the error card's action button.
//
// A connection-level failure that survives every retry ("Network failed: Broken
// pipe") rendered as a bare error with a Retry button only. That is misleading:
// an exhausted balance or a rejected API key reaches the client as a dead
// socket, so the user saw "network problem" and had nothing to click. The card
// now offers a "check account" action pointing at the provider console, and the
// top-up case keeps its distinct "Top up" label.

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const sourcePath = name => path.resolve(__dirname, "../../lib/clacky/web", name);

const autoStub = (extra = {}) => new Proxy(extra, {
  get: (target, key) => (key in target ? target[key] : () => {}),
});

class Element {
  constructor(tag = "div") {
    this.tagName = tag;
    this.style = { setProperty() {} };
    this.dataset = {};
    this.attrs = {};
    this.children = [];
    this.handlers = {};
    this.classes = new Set();
    this._className = "";
    this.textContent = "";
    this.innerHTML = "";
    this.hidden = false;
    this.disabled = false;
    this.classList = {
      add: n => this.classes.add(n),
      remove: n => this.classes.delete(n),
      toggle: (n, on) => (on ? this.classes.add(n) : this.classes.delete(n)),
      contains: n => this.classes.has(n),
    };
  }
  set className(v) { this._className = v; this.classes = new Set(v.split(/\s+/).filter(Boolean)); }
  get className() { return this._className; }
  setAttribute(k, v) { this.attrs[k] = v; }
  removeAttribute(k) { delete this.attrs[k]; }
  addEventListener(k, fn) { this.handlers[k] = fn; }
  removeEventListener() {}
  appendChild(child) { this.children.push(child); child.parentNode = this; return child; }
  append(...kids) { kids.forEach(k => this.appendChild(k)); }
  prepend(child) { this.children.unshift(child); return child; }
  remove() {}
  replaceChildren(...kids) { this.children = kids; }
  replaceWith() {}
  insertBefore(child) { this.children.unshift(child); return child; }
  querySelector() { return new Element(); }
  querySelectorAll() { return []; }
  getBoundingClientRect() { return { top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0 }; }
  contains() { return false; }
  closest() { return null; }
  focus() {}
}

function boot() {
  const appended = [];
  const record = (type, html) => appended.push({ type, html });

  const document = {
    createElement: tag => new Element(tag),
    createDocumentFragment: () => new Element("fragment"),
    createTextNode: text => ({ nodeType: 3, textContent: text }),
    getElementById: () => new Element(),
    addEventListener() {},
    querySelector: () => null,
    querySelectorAll: () => [],
    body: new Element(),
  };

  const context = {
    console, Date, Map, Set, Math, JSON, Promise, URLSearchParams,
    setTimeout, clearTimeout,
    document,
    fetch: async () => ({ ok: false, json: async () => ({}) }),
    I18n: { t: key => key, lang: () => "en" },
    WS: { ready: true, onEvent() {}, setSubscribedSession() {}, send() {} },
    Sessions: autoStub({ appendMsg: record, collapseToolGroup() {} }),
    Clacky: { Sessions: autoStub({ appendMsg: record, collapseToolGroup() {} }) },
    $: () => new Element(),
    escapeHtml: s => String(s === undefined || s === null ? "" : s),
    localStorage: { getItem: () => null, setItem() {}, removeItem() {} },
    Router: autoStub(),
    Projects: autoStub(),
    Tasks: autoStub(),
    Skills: autoStub(),
    Composer: autoStub({ text: () => "", chips: () => [] }),
    IME: autoStub({ track: () => ({ isComposing: () => false, dispose() {} }) }),
    alert() {},
  };
  context.window = context;
  context.globalThis = context;
  vm.createContext(context);

  vm.runInContext(fs.readFileSync(sourcePath("ws-dispatcher.js"), "utf8"), context);
  vm.runInContext("window.__renderErrorEvent = window.renderErrorEvent;", context);

  return {
    renderErrorEvent: context.__renderErrorEvent,
    last: () => appended[appended.length - 1],
    count: () => appended.length,
  };
}

function tests() {
  // 1. An exhausted-retry network failure carrying a console URL offers the
  //    neutral "check account" action — not the top-up wording.
  {
    const ui = boot();
    ui.renderErrorEvent({
      code: null,
      message: "llm.error.network_failed",
      top_up_url: "https://www.openclacky.com/llm_keys",
      raw_message: "Broken pipe",
    });
    const { type, html } = ui.last();
    assert.equal(type, "error");
    assert.ok(html.includes('class="error-action-btn"'), "network failure renders an action button");
    assert.ok(html.includes('href="https://www.openclacky.com/llm_keys"'), "button points at the console");
    assert.ok(html.includes("error.check_account.action"), "label is the neutral check-account wording");
    assert.ok(!html.includes("error.insufficient_credit.action"), "network failure is not labelled as top-up");
    assert.ok(html.includes("error-raw-detail"), "raw cause stays behind the detail toggle");
  }

  // 2. Credits still get the top-up label — the two causes stay distinguishable.
  {
    const ui = boot();
    ui.renderErrorEvent({
      code: "insufficient_credit",
      top_up_url: "https://www.openclacky.com/llm_keys",
      raw_message: "insufficient account credit",
    });
    const html = ui.last().html;
    assert.ok(html.includes("error.insufficient_credit.action"), "credit failure keeps the top-up label");
    assert.ok(!html.includes("error.check_account.action"));
  }

  // 3. A model outside the free-trial allow-list behaves like the credit case.
  {
    const ui = boot();
    ui.renderErrorEvent({
      code: "model_not_allowed",
      message: "Model not allowed on this key",
      top_up_url: "https://www.openclacky.com/llm_keys",
    });
    assert.ok(ui.last().html.includes("error.insufficient_credit.action"));
  }

  // 4. Errors with no known console (custom base_url) stay button-free.
  {
    const ui = boot();
    ui.renderErrorEvent({ code: null, message: "boom" });
    const html = ui.last().html;
    assert.ok(!html.includes("error-action-btn"), "no URL means no button");
    assert.equal(html, "boom");
  }
}

tests();
console.log("error_action_button_test: ok");
