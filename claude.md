# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## アプリについて
- macOSのメニューバーに常駐するメモアプリ
- メモというかテキストエリアがあればよい
- ネット経由で他の端末と共有とかいらない。ローカル完結
- 即時保存される
- 終了して再起動しても終了時のは残っている
- 3ページあってページ切り替えできる
- ファイルへの書き出し、読み出し機能はいらない
- プレーンテキストだけを扱う
- 書式付きテキストをペーストされたときには書式を捨ててテキストだけをペーストする
- メニューバーのアイコンをクリックすると開く、ウィンドウ外をクリックすると閉じる
- stay on top(ピン留め)スイッチ付ける。スイッチONでウィンドウ外をクリックしても閉じない、他のアプリの裏に行かない
- 開く位置、大きさはユーザーが変えられて、保存される
- フォントを変える設定UIも付ける。設定UIに入るにはメニューバーのアイコンの右クリックメニューから

## 技術スタック
- SwiftUI + AppKit（NSViewRepresentable でプレーンテキスト強制）
- Swift Package Manager でビルド（macOS 14+）
- データ保存は UserDefaults

## ビルド方法
- デバッグビルド: `swift build`
- リリースビルド + .appバンドル作成: `./build.sh`
- 実行: `open StayMemo.app`

## アーキテクチャ
- `StayMemoApp.swift` - @main エントリポイント、MenuBarExtra定義、AppDelegate（右クリックメニュー）
- `MemoStore.swift` - @Observable データモデル、UserDefaults永続化（シングルトン）
- `MemoView.swift` - メインUI（ページ切替、ピン留めトグル、テキスト編集）
- `PlainTextView.swift` - NSTextView ラッパー（isRichText=false でプレーンテキスト強制）
- `SettingsView.swift` - フォント設定UI
