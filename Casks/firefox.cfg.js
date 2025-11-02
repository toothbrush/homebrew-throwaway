// IMPORTANT: Start your code on the 2nd line, also this is Javascript
pref("app.normandy.first_run", false);
pref("sidebar.main.tools", "history,bookmarks"); // no AI plz
pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
pref("browser.urlbar.quantumbar", false);

// from https://www.reddit.com/r/firefox/comments/1c67r0c/adding_a_chrome_folder_to_all_new_profiles/
const {classes: Cc, interfaces: Ci, utils: Cu} = Components;
let Services = globalThis.Services || ChromeUtils.import("resource://gre/modules/Services.jsm").Services;
Cu.import("resource://gre/modules/FileUtils.jsm");
var profileDir = Services.dirsvc.get("ProfD", Ci.nsIFile);
var chromeDir = profileDir.clone();
chromeDir.append("chrome");
// If chrome folder isn't there, it's a new profile
if (!chromeDir.exists()) {
  Cu.reportError("chrome folder not found");
  var defaultProfileDir = Services.dirsvc.get("GreD", Ci.nsIFile);
  defaultProfileDir.append("defaults");
  defaultProfileDir.append("profile");
  try {
    Cu.reportError("copying profile folder");
    copyDir(defaultProfileDir, profileDir);
  } catch (e) {
    Cu.reportError(e);
  }
}
function copyDir(aOriginal, aDestination) {
  var enumerator = aOriginal.directoryEntries;
  while (enumerator.hasMoreElements()) {
    var file = enumerator.getNext().QueryInterface(Ci.nsIFile);
    if (file.isDirectory()) {
      var subdir = aDestination.clone();
      subdir.append(file.leafName);
      try {
        subdir.create(Ci.nsIFile.DIRECTORY_TYPE, FileUtils.PERMS_DIRECTORY);
        copyDir(file, subdir);
      } catch (e) {
        Cu.reportError(e);
      }
    } else {
      try {
        file.copyTo(aDestination, null);
      } catch (e) {
        Cu.reportError(e);
      }
    }
  }
}
