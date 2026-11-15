cask "xingyu-ime" do
  version "1.0.0"
  sha256 "26ab5d54cb12eea338f0bd02e95aa87e037a10dac6b56d7eb119427316f591e2"

  url "https://github.com/ADT109119/XingYu-IME/releases/download/v#{version}/XingYuIME-#{version}-universal.zip"
  name "行魚輸入法"
  name "XingYu IME"
  desc "專為 macOS 打造的 Rust × Swift 智慧繁體注音與中英混打輸入法"
  homepage "https://github.com/ADT109119/XingYu-IME"

  depends_on macos: ">= :ventura"

  input_method "XingYuIME.app"

  preflight do
    system_command "/usr/bin/killall", args: ["XingYuIME"], must_succeed: false
  end

  postflight do
    app_path = "#{Dir.home}/Library/Input Methods/XingYuIME.app"
    bundle_id = "com.jerryyen.inputmethod.XingYuIME"

    # Ad-hoc 簽章無 Apple Developer ID 公證，需移除 quarantine 屬性以避免 Gatekeeper 阻擋輸入法載入
    system_command "/usr/bin/xattr", args: ["-cr", app_path], must_succeed: false

    # 註冊並啟用 macOS 輸入來源
    swift_script = <<~SWIFT
      import Carbon
      import Foundation

      let url = URL(fileURLWithPath: #{app_path.inspect})
      _ = TISRegisterInputSource(url as CFURL)
      let filter = [kTISPropertyBundleID as String: #{bundle_id.inspect}] as CFDictionary
      if let list = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource] {
          for s in list {
              _ = TISEnableInputSource(s)
          }
      }
    SWIFT
    system_command "/usr/bin/swift", args: ["-e", swift_script], must_succeed: false

    # 同步寫入系統偏好輸入法清單
    python_script = <<~PYTHON
      import os, plistlib
      plist_path = os.path.expanduser("~/Library/Preferences/com.apple.HIToolbox.plist")
      if os.path.exists(plist_path):
          with open(plist_path, "rb") as f:
              data = plistlib.load(f)
          sources = data.get("AppleEnabledInputSources", [])
          bundle_id = #{bundle_id.inspect}
          mode_id = f"{bundle_id}.bopomofo"
          if not any(s.get("Input Mode") == mode_id for s in sources):
              sources.append({"Bundle ID": bundle_id, "Input Mode": mode_id, "InputSourceKind": "Input Mode"})
          if not any(s.get("Bundle ID") == bundle_id and s.get("InputSourceKind") == "Keyboard Input Method" for s in sources):
              sources.append({"Bundle ID": bundle_id, "InputSourceKind": "Keyboard Input Method"})
          data["AppleEnabledInputSources"] = sources
          with open(plist_path, "wb") as f:
              plistlib.dump(data, f)
    PYTHON
    system_command "/usr/bin/python3", args: ["-c", python_script], must_succeed: false

    # 重新載入系統輸入法選單
    system_command "/usr/bin/killall", args: ["TextInputMenuAgent"], must_succeed: false
    system_command "/usr/bin/killall", args: ["TextInputSwitcher"], must_succeed: false
  end

  uninstall quit:   "com.jerryyen.inputmethod.XingYuIME",
            signal: ["TERM", "XingYuIME"],
            delete: "~/Library/Input Methods/XingYuIME.app"

  zap trash: [
    "~/Library/Application Support/XingYuIME",
    "~/Library/Preferences/com.jerryyen.inputmethod.XingYuIME.plist",
  ]

  caveats <<~EOS
    行魚輸入法已安裝至 ~/Library/Input Methods/XingYuIME.app。

    若選單列尚未出現「行魚輸入法」：
      1. 開啟「系統設定」→「鍵盤」→「文字輸入」點擊「編輯」
      2. 點擊「+」→「繁體中文」→ 選擇「行魚輸入法」並加入
      3. 若首次註冊後仍未出現，請重新登入 macOS 即可
  EOS
end
