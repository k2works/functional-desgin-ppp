(ns composite-pattern.switchable
  "Composite パターン - Switchable インターフェース

   スイッチ可能なオブジェクトの共通インターフェースを定義します。")

(defmulti turn-on
  "スイッチをオンにする"
  :type)

(defmulti turn-off
  "スイッチをオフにする"
  :type)
