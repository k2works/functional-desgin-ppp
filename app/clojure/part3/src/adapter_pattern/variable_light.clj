(ns adapter-pattern.variable-light
  "Adapter パターン - VariableLight (Adaptee)

   可変強度を持つライトの実装です。
   既存のインターフェース（強度指定）を持ち、
   単純なオン/オフインターフェースとは互換性がありません。")

(defn turn-on-light
  "ライトを指定した強度で点灯する"
  [intensity]
  (println (str "VariableLight: intensity set to " intensity))
  {:intensity intensity})
