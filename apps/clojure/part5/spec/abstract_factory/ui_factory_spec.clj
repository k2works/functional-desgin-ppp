(ns abstract-factory.ui-factory-spec
  (:require [speclj.core :refer :all]
            [abstract-factory.ui-factory :as ui]))

(describe "Abstract Factory パターン - UIFactory"

  (context "WindowsUIFactory"
    (it "ボタンを作成できる"
      (let [factory (ui/make-windows-factory)
            button (ui/create-button factory "OK")]
        (should= "[OK]" (ui/render button))))

    (it "テキストフィールドを作成できる"
      (let [factory (ui/make-windows-factory)
            field (ui/create-text-field factory "Enter name")]
        (should= "|Enter name|" (ui/render field))))

    (it "チェックボックスを作成できる"
      (let [factory (ui/make-windows-factory)
            checked (ui/create-checkbox factory "Remember me" true)
            unchecked (ui/create-checkbox factory "Remember me" false)]
        (should= "[x] Remember me" (ui/render checked))
        (should= "[ ] Remember me" (ui/render unchecked)))))

  (context "MacOSUIFactory"
    (it "ボタンを作成できる"
      (let [factory (ui/make-macos-factory)
            button (ui/create-button factory "OK")]
        (should= "(OK)" (ui/render button))))

    (it "テキストフィールドを作成できる"
      (let [factory (ui/make-macos-factory)
            field (ui/create-text-field factory "Enter name")]
        (should= "[Enter name]" (ui/render field))))

    (it "チェックボックスを作成できる"
      (let [factory (ui/make-macos-factory)
            checked (ui/create-checkbox factory "Remember me" true)]
        (should= "(x) Remember me" (ui/render checked)))))

  (context "LinuxUIFactory"
    (it "ボタンを作成できる"
      (let [factory (ui/make-linux-factory)
            button (ui/create-button factory "OK")]
        (should= "<OK>" (ui/render button))))

    (it "テキストフィールドを作成できる"
      (let [factory (ui/make-linux-factory)
            field (ui/create-text-field factory "Enter name")]
        (should= "{Enter name}" (ui/render field))))

    (it "チェックボックスを作成できる"
      (let [factory (ui/make-linux-factory)
            checked (ui/create-checkbox factory "Remember me" true)]
        (should= "<x> Remember me" (ui/render checked)))))

  (context "ファクトリの交換"
    (it "同じコードで異なるプラットフォームのUIを作成できる"
      (let [create-form (fn [factory]
                          {:button (ui/create-button factory "Submit")
                           :field (ui/create-text-field factory "Email")
                           :checkbox (ui/create-checkbox factory "Subscribe" false)})
            windows-form (create-form (ui/make-windows-factory))
            macos-form (create-form (ui/make-macos-factory))]
        (should= "[Submit]" (ui/render (:button windows-form)))
        (should= "(Submit)" (ui/render (:button macos-form)))))))

(run-specs)
