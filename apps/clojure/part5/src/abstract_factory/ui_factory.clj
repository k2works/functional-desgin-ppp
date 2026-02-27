(ns abstract-factory.ui-factory
  "Abstract Factory パターン - UI Factory

   UI コンポーネントを生成するファクトリの例です。
   プラットフォーム別の UI を生成します。")

;; =============================================================================
;; UI Component インターフェース
;; =============================================================================

(defmulti render
  "コンポーネントを描画する"
  (fn [component] (::type component)))

;; =============================================================================
;; Button
;; =============================================================================

(defn make-button
  "ボタンを作成"
  [label platform]
  {::type ::button
   ::label label
   ::platform platform})

(defmethod render ::button [button]
  (let [label (::label button)
        platform (::platform button)]
    (case platform
      :windows (str "[" label "]")
      :macos (str "(" label ")")
      :linux (str "<" label ">"))))

;; =============================================================================
;; TextField
;; =============================================================================

(defn make-text-field
  "テキストフィールドを作成"
  [placeholder platform]
  {::type ::text-field
   ::placeholder placeholder
   ::platform platform})

(defmethod render ::text-field [field]
  (let [placeholder (::placeholder field)
        platform (::platform field)]
    (case platform
      :windows (str "|" placeholder "|")
      :macos (str "[" placeholder "]")
      :linux (str "{" placeholder "}"))))

;; =============================================================================
;; Checkbox
;; =============================================================================

(defn make-checkbox
  "チェックボックスを作成"
  [label checked? platform]
  {::type ::checkbox
   ::label label
   ::checked? checked?
   ::platform platform})

(defmethod render ::checkbox [checkbox]
  (let [label (::label checkbox)
        checked? (::checked? checkbox)
        platform (::platform checkbox)
        mark (if checked? "x" " ")]
    (case platform
      :windows (str "[" mark "] " label)
      :macos (str "(" mark ") " label)
      :linux (str "<" mark "> " label))))

;; =============================================================================
;; Abstract Factory インターフェース
;; =============================================================================

(defmulti create-button
  "ボタンを作成"
  (fn [factory _label] (::factory-type factory)))

(defmulti create-text-field
  "テキストフィールドを作成"
  (fn [factory _placeholder] (::factory-type factory)))

(defmulti create-checkbox
  "チェックボックスを作成"
  (fn [factory _label _checked?] (::factory-type factory)))

;; =============================================================================
;; WindowsUIFactory
;; =============================================================================

(defn make-windows-factory
  "Windows UI ファクトリを作成"
  []
  {::factory-type ::windows})

(defmethod create-button ::windows [_factory label]
  (make-button label :windows))

(defmethod create-text-field ::windows [_factory placeholder]
  (make-text-field placeholder :windows))

(defmethod create-checkbox ::windows [_factory label checked?]
  (make-checkbox label checked? :windows))

;; =============================================================================
;; MacOSUIFactory
;; =============================================================================

(defn make-macos-factory
  "macOS UI ファクトリを作成"
  []
  {::factory-type ::macos})

(defmethod create-button ::macos [_factory label]
  (make-button label :macos))

(defmethod create-text-field ::macos [_factory placeholder]
  (make-text-field placeholder :macos))

(defmethod create-checkbox ::macos [_factory label checked?]
  (make-checkbox label checked? :macos))

;; =============================================================================
;; LinuxUIFactory
;; =============================================================================

(defn make-linux-factory
  "Linux UI ファクトリを作成"
  []
  {::factory-type ::linux})

(defmethod create-button ::linux [_factory label]
  (make-button label :linux))

(defmethod create-text-field ::linux [_factory placeholder]
  (make-text-field placeholder :linux))

(defmethod create-checkbox ::linux [_factory label checked?]
  (make-checkbox label checked? :linux))
