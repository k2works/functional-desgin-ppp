(ns adapter-pattern.switchable
  "Adapter パターン - Switchable インターフェース (Target)

   クライアントが期待するターゲットインターフェースを定義します。
   単純なオン/オフ機能を提供します。")

(defmulti turn-on
  "スイッチをオンにする"
  :type)

(defmulti turn-off
  "スイッチをオフにする"
  :type)
