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
        "AutofillAddressEnabled": false,
        "AutofillCreditCardEnabled": false,
        "BackgroundAppUpdate": false,
        "CaptivePortal": false,
        # todo cookies session lifetime SanitizeOnShutdown
        "Cookies": {
          "Allow": ["https://seats.aero"],
          "Locked": true,
          "Behavior": "reject-tracker-and-partition-foreign",
          "BehaviorPrivateBrowsing": "reject-tracker-and-partition-foreign",
        },
        "DisableAppUpdate": true,
        "DisableBuiltinPDFViewer": true,
        "DisableFeedbackCommands": true,
        "DisableFirefoxAccounts": true,
        "DisableFirefoxScreenshots": true,
        "DisableFirefoxStudies": true,
        "DisableMasterPasswordCreation": true,
        "DisablePocket": true,
        "DisableProfileImport": true,
        "DisableProfileRefresh": true,
        "DisableSetDesktopBackground": true,
        "DisableSystemAddonUpdate": true,
        "DisableTelemetry": true,
        "DisplayBookmarksToolbar": "always",
        "DontCheckDefaultBrowser": true,
        "EnableTrackingProtection": {
          "Value": true,
          "Locked": true,
          "Cryptomining": true,
          "Fingerprinting": true,
          "EmailTracking": true,
          "SuspectedFingerprinting": true,
        },
        "EncryptedMediaExtensions": {
          "Enabled": false,
          "Locked": true,
        },
        "ExtensionSettings": {
          "*": {
            "blocked_install_message": "Please adjust Homebrew Cask to configure addons.",
            "installation_mode": "blocked",
          },
        }.merge( # XXX(pd) 20251102: Hm, consider just being literal here, then setting `private_browsing` for uBlock.
          Hash[extensions.collect { |ext| [ext[:id], {"installation_mode": "force_installed", "install_url": ext[:uri]}] }]
        ),
        "ExtensionUpdate": true,
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
        "GenerativeAI": {
          "Enabled": false,
          "Chatbot": false,
          "LinkPreviews": false,
          "TabGroups": false,
          "Locked": true,
        },
        "Homepage": {
          "URL": "about:blank",
          "Locked": true,
          "Additional": [],
          "StartPage": "none",
        },
        "HttpsOnlyMode": "enabled", # HTTPS-Only Mode is on by default, but the user can turn it off.
        "InstallAddonsPermission": {
          "Allow": [],
          "Default": false,
        },
        "ManagedBookmarks": [
          {"toplevel_name": "Managed bookmarks"},
          {"url": "https://news.ycombinator.com", "name": "BOW"},
        ],
        "NewTabPage": false,
        "NoDefaultBookmarks": true,
        "OfferToSaveLogins": false,
        "OverrideFirstRunPage": "",
        "OverridePostUpdatePage": "",
        "PasswordManagerEnabled": false,
        "PDFjs": {
          "Enabled": false,
        },
        "Permissions": {
          "Camera": { # Explicit origins only in Allow/Block, no wildcards.
            "Allow": [], "Block": [],
            "BlockNewRequests": true,
            "Locked": false,
          },
          "Microphone": {
            "Allow": [], "Block": [],
            "BlockNewRequests": true,
            "Locked": false,
          },
          "Location": {
            "Allow": [], "Block": [],
            "BlockNewRequests": true,
            "Locked": false,
          },
          "Notifications": {
            "Allow": [], "Block": [],
            "BlockNewRequests": true,
            "Locked": false,
          },
          "Autoplay": {
            "Default": "block-audio-video",
            "Locked": false,
          },
          "VirtualReality": {
            "Allow": [], "Block": [],
            "BlockNewRequests": true,
            "Locked": false,
          },
          "ScreenShare": {
            "Allow": [], "Block": [],
            "BlockNewRequests": true,
            "Locked": false,
          }
        },
        "PopupBlocking": {
          "Allow": [],
          "Default": true,
          "Locked": false,
        },
        "Preferences": {
          "browser.aboutwelcome.enabled": false,
          "browser.aboutConfig.showWarning": false,
        },
        "SearchEngines": {
          "PreventInstalls": true,
        },
        "SearchSuggestEnabled": false,
        "SkipTermsOfUse": true,
        "UserMessaging": {
          "ExtensionRecommendations": false,
          "FeatureRecommendations": false,
          "UrlbarInterventions": false,
          "SkipOnboarding": true,
          "MoreFromMozilla": false,
          "FirefoxLabs": false,
          "Locked": false
        },
      }
    }

    FileUtils.mkdir_p("#{staged_path}/Firefox.app/Contents/Resources/distribution")
    File.open("#{staged_path}/Firefox.app/Contents/Resources/distribution/policies.json", 'w') do |f|
      f.write(policies.to_json)
    end
    # }}}

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

    # Hack up a profile folder with some defaults
    # {{{
    FileUtils.mkdir_p(File.expand_path("~/Library/Application Support/Firefox/Profiles/8qha96fn.default"))
    FileUtils.mkdir_p(File.expand_path("~/Library/Application Support/Firefox/Profiles/jlp5eosb.default-release"))
    File.open(File.expand_path("~/Library/Application Support/Firefox/installs.ini"), 'w') do |f|
      f.write <<~EOS
        [2656FF1E876E9973]
        Default=Profiles/jlp5eosb.default-release
        Locked=1

      EOS
    end

    File.open(File.expand_path("~/Library/Application Support/Firefox/profiles.ini"), 'w') do |f|
      f.write <<~EOS
        [Profile1]
        Name=default
        IsRelative=1
        Path=Profiles/8qha96fn.default
        Default=1

        [Profile0]
        Name=default-release
        IsRelative=1
        Path=Profiles/jlp5eosb.default-release

        [General]
        StartWithLastProfile=1
        Version=2

        [Install2656FF1E876E9973]
        Default=Profiles/jlp5eosb.default-release
        Locked=1

      EOS
    end

    # Sweet, now we have a spot where we can put customisations.
    FileUtils.mkdir_p(File.expand_path("~/Library/Application Support/Firefox/Profiles/jlp5eosb.default-release/chrome"))
    FileUtils.cp("#{__dir__}/userChrome.css",
                 File.expand_path("~/Library/Application Support/Firefox/Profiles/jlp5eosb.default-release/chrome/userChrome.css"))
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
