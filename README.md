# ADT109119 Homebrew Tap

Official Homebrew tap for [行魚輸入法 (XingYu IME)](https://github.com/ADT109119/XingYu-IME).

## Installation

```bash
brew install --cask ADT109119/tap/xingyu-ime
```

> If Homebrew 7.x+ prompts that the tap is untrusted, run `brew trust ADT109119/tap` first.

Or tap first:

```bash
brew tap ADT109119/tap
brew install --cask xingyu-ime
```

## Upgrade

```bash
brew upgrade --cask xingyu-ime
```

## Uninstall

```bash
brew uninstall --cask xingyu-ime
# Or remove user dictionary and learning database as well:
brew uninstall --zap --cask xingyu-ime
```
