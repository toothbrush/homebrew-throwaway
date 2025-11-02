cask "fuckedfox" do
  version "144.0.2"

  # TODO: ESR version.
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

    # Addons bundling - https://support.mozilla.org/en-US/kb/deploying-firefox-with-extensions
    # {{{
    extensions = [
      { uri: "https://addons.mozilla.org/firefox/downloads/latest/tree-style-tab/latest.xpi", id: "treestyletab@piro.sakura.ne.jp" },
      { uri: "https://addons.mozilla.org/firefox/downloads/latest/redirector/latest.xpi", id: "redirector@einaregilsson.com" },
      { uri: "https://addons.mozilla.org/firefox/downloads/latest/saka-key/latest.xpi", id: "{46104586-98c3-407e-a349-290c9ff3594d}" },
      { uri: "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi", id: "uBlock0@raymondhill.net" },
    ]
    # }}}

    # distribution policies - https://mozilla.github.io/policy-templates/
    # See also https://github.com/mozilla/policy-templates/blob/master/linux/policies.json
    # {{{
    policies = {
      "policies": {
        "AppUpdateURL": "http://127.0.0.1/",
        "CaptivePortal": false,
        "DisableFeedbackCommands": true,
        "DisableFirefoxAccounts": true,
        "DisableFirefoxScreenshots": true,
        "DisableFirefoxStudies": true,
        "DisablePocket": true,
        "DisableSystemAddonUpdate": true,
        "DisableTelemetry": true,
        "ExtensionUpdate": false,
        "FirefoxHome": {
          "Search": false,
          "TopSites": false,
          "SponsoredTopSites": false,
          "Highlights": false,
          "Pocket": false,
          "SponsoredPocket": false,
          "Snippets": false,
          "Locked": true
        },
        "FirefoxSuggest": {
          "WebSuggestions": false,
          "SponsoredSuggestions": false,
          "ImproveSuggest": false,
          "Locked": true
        },
        "NewTabPage": false,
        "OverrideFirstRunPage": "",
        "OverridePostUpdatePage": "",
        "SearchSuggestEnabled": false,
        "UserMessaging": {
          "ExtensionRecommendations": false,
          "FeatureRecommendations": false,
          "UrlbarInterventions": false,
          "SkipOnboarding": true,
          "MoreFromMozilla": false,
          "FirefoxLabs": false,
          "Locked": false
        },
        "DisableAppUpdate": true,
        "SkipTermsOfUse": true,
        "SearchEngines": {
          "PreventInstalls": true,
        },
        "NoDefaultBookmarks": true,
        "DisableProfileImport": true,
        "DontCheckDefaultBrowser": true,
        "Preferences": {
          "browser.aboutwelcome.enabled": false,
          "browser.aboutConfig.showWarning": false,
        },
        "Homepage": {
          "URL": "about:blank",
          "Locked": true,
          "Additional": [],
          "StartPage": "none",
        },
        "Bookmarks": [
          {"Title": "BOW", "URL": "https://news.ycombinator.com", "Favicon": "https://news.ycombinator.com/favicon.ico", "Placement": "toolbar"}
        ],
        "ExtensionSettings": {
          "*": {
            "blocked_install_message": "Please adjust Homebrew Cask to configure addons.",
            # "install_sources": ["https://yourwebsite.com/*"],
            "installation_mode": "blocked",
            # "allowed_types": ["extension"]
          },
          # "https-everywhere@eff.org": {
          #   "installation_mode": "allowed"
          # }
        }.merge(
          Hash[extensions.collect { |ext| [ext[:id], {"installation_mode": "force_installed", "install_url": ext[:uri]}] }]
        ),
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

    # Put our firefox.cfg (which, confusingly, is JavaScript) in place:
    FileUtils.cp("#{__dir__}/firefox.cfg.js",
                 "#{staged_path}/Firefox.app/Contents/Resources/firefox.cfg")
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
