cask "xingyu-ime" do
  version "1.0.1"
  sha256 "d1e5033428f5172c5fe7466a57459db440b60ffc1c1683cc979e495323de1df6"

  url "https://github.com/ADT109119/XingYu-IME/releases/download/v#{version}/XingYuIME-#{version}-universal.zip"
  name "行魚輸入法"
  name "XingYu IME"
  desc "Rust × Swift 智慧繁體注音與中英混打輸入法"
  homepage "https://github.com/ADT109119/XingYu-IME"

  depends_on macos: :ventura

  input_method "XingYuIME.app"

  preflight_steps do
    terminate_process "XingYuIME"
    run "/usr/bin/xattr",
        args:         ["-dr", "com.apple.quarantine", "{{staged_path}}/XingYuIME.app"],
        must_succeed: false
  end

  postflight_steps do
    run "/usr/bin/python3",
        args:           [
          "-c",
          <<~PYTHON,
            import os, plistlib, pwd
            real_home = pwd.getpwuid(os.getuid()).pw_dir
            plist_path = os.path.join(real_home, "Library/Preferences/com.apple.HIToolbox.plist")
            if os.path.exists(plist_path):
                with open(plist_path, "rb") as f:
                    data = plistlib.load(f)
                sources = data.get("AppleEnabledInputSources", [])
                bundle_id = "com.jerryyen.inputmethod.XingYuIME"
                mode_id = f"{bundle_id}.bopomofo"
                if not any(s.get("Input Mode") == mode_id for s in sources):
                    sources.append({"Bundle ID": bundle_id, "Input Mode": mode_id, "InputSourceKind": "Input Mode"})
                if not any(s.get("Bundle ID") == bundle_id and s.get("InputSourceKind") == "Keyboard Input Method" for s in sources):
                    sources.append({"Bundle ID": bundle_id, "InputSourceKind": "Keyboard Input Method"})
                data["AppleEnabledInputSources"] = sources
                with open(plist_path, "wb") as f:
                    plistlib.dump(data, f)
          PYTHON
        ],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home,
        must_succeed:   false

    terminate_process "TextInputMenuAgent"
    terminate_process "TextInputSwitcher"
  end

  uninstall quit:   "com.jerryyen.inputmethod.XingYuIME",
            signal: ["TERM", "XingYuIME"]

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
