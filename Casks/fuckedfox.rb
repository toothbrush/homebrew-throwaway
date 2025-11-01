cask "fuckedfox" do
  version "144.0.2"

  # TODO: Can we hack livecheck to .. do something latest?
  language "en", default: true do
    sha256 "c67e649a9ef2d23c929ca1b9a87b10591e06303cdf0d9e2395e64bcf7bc0f673"
    "en-US"
  end

  url "https://download-installer.cdn.mozilla.net/pub/firefox/releases/#{version}/mac/#{language}/Firefox%20#{version}.dmg",
      verified: "download-installer.cdn.mozilla.net/pub/firefox/releases/"
  name "Mozilla Firefox"
  desc "Web browser"
  homepage "https://www.mozilla.org/firefox/"

  livecheck do
    url "https://product-details.mozilla.org/1.0/firefox_versions.json"
    strategy :json do |json|
      json["LATEST_FIREFOX_VERSION"]
    end
  end

  auto_updates false
  conflicts_with cask: [
    "firefox",
    "firefox@beta",
    "firefox@cn",
    "firefox@esr",
  ]

  app "Firefox.app"
  # shim script (https://github.com/Homebrew/homebrew-cask/issues/18809)
  shimscript = "#{staged_path}/firefox.wrapper.sh"
  binary shimscript, target: "firefox"

  resource "tree_style_tabs" do
    # From https://addons.mozilla.org/en-US/firefox/addon/tree-style-tab/
    url "https://addons.mozilla.org/firefox/downloads/file/4602712/tree_style_tab-4.2.7.xpi"
    sha1 "f0bc6a44d406a57c831044aa45e0965c9475caf1"
  end

  preflight do
    File.write shimscript, <<~EOS
      #!/bin/bash
      exec '#{appdir}/Firefox.app/Contents/MacOS/firefox' "$@"
    EOS

    system_command "xattr",
                   args: ["-dr", "com.apple.application-instance", "#{staged_path}/Firefox.app"]
    system_command "xattr",
                   args: ["-dr", "com.apple.macl", "#{staged_path}/Firefox.app"]
    system_command "xattr",
                   args: ["-dr", "com.apple.provenance", "#{staged_path}/Firefox.app"]
    system_command "xattr",
                   args: ["-dr", "com.apple.quarantine", "#{staged_path}/Firefox.app"]

    # XXX(pd) 20251101: Attempt to .. set things up reasonably.

    # distribution policies - https://mozilla.github.io/policy-templates/
    # See also https://github.com/mozilla/policy-templates/blob/master/linux/policies.json
    # {{{
    policies = {
      "policies": {
        "DisableAppUpdate": true,
        "SkipTermsOfUse": true,
        "SearchEngines": {
          "PreventInstalls": true,
        },
        "Preferences": {
          "browser.aboutwelcome.enabled": false,
          "browser.aboutConfig.showWarning": false,
        }
      }
    }

    FileUtils.mkdir_p("#{staged_path}/Firefox.app/Contents/Resources/distribution")
    File.open("#{staged_path}/Firefox.app/Contents/Resources/distribution/policies.json", 'w') do |f|
      f.write(policies.to_json)
    end
    # }}}

    # TODO userChrome.css

    # AutoConfig - https://support.mozilla.org/en-US/kb/customizing-firefox-using-autoconfig
    # {{{
    FileUtils.mkdir_p("#{staged_path}/Firefox.app/Contents/Resources/defaults/pref")
    File.open("#{staged_path}/Firefox.app/Contents/Resources/defaults/pref/autoconfig.js", 'w') do |f|
      f.write <<~EOS
        pref("general.config.filename", "firefox.cfg");
        pref("general.config.obscure_value", 0);
      EOS
    end

    File.open("#{staged_path}/Firefox.app/Contents/Resources/firefox.cfg", 'w') do |f|
      f.write <<~EOS
        // IMPORTANT: Start your code on the 2nd line, also this is Javascript
        pref("app.normandy.first_run", false)
        pref("sidebar.main.tools", "history,bookmarks") // no AI plz
        pref("toolkit.legacyUserProfileCustomizations.stylesheets", true)
        pref("browser.urlbar.quantumbar", false)
      EOS
    end
    # }}}

    # Addons
    # TODO addons bundling - https://support.mozilla.org/en-US/kb/deploying-firefox-with-extensions
    # {{{

    extension_path = "#{staged_path}/Firefox.app/Contents/Resources/distribution/extensions"
    FileUtils.mkdir_p(extension_path)

    # Additional downloads can be defined as resources (see above).
    # The stage method will create a temporary directory and yield
    # to a block.
    resource("tree_style_tabs").stage(extension_path)
    FileUtils.mv(extension_path.join("tree_style_tab-4.2.7.xpi"),
                 extension_path.join("treestyletab@piro.sakura.ne.jp.xpi"))

    # }}}
  end

  uninstall quit: "org.mozilla.firefox"

  zap trash: [
        "/Library/Logs/DiagnosticReports/firefox_*",
        "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/org.mozilla.firefox.sfl*",
        "~/Library/Application Support/CrashReporter/firefox_*",
        "~/Library/Application Support/Firefox",
        "~/Library/Caches/Firefox",
        "~/Library/Caches/Mozilla/updates/Applications/Firefox",
        "~/Library/Caches/org.mozilla.crashreporter",
        "~/Library/Caches/org.mozilla.firefox",
        "~/Library/Preferences/org.mozilla.crashreporter.plist",
        "~/Library/Preferences/org.mozilla.firefox.plist",
        "~/Library/Saved Application State/org.mozilla.firefox.savedState",
        "~/Library/WebKit/org.mozilla.firefox",
      ],
      rmdir: [
        "~/Library/Application Support/Mozilla", #  May also contain non-Firefox data
        "~/Library/Caches/Mozilla",
        "~/Library/Caches/Mozilla/updates",
        "~/Library/Caches/Mozilla/updates/Applications",
      ]
end
