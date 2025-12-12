(ns composite-pattern.shape
  "Composite パターン - Shape インターフェース

   形状オブジェクトの共通インターフェースを定義します。
   マルチメソッドを使用して多態性を実現します。"
  (:require [clojure.spec.alpha :as s]))

(s/def ::type keyword?)
(s/def ::shape-type (s/keys :req [::type]))

(defmulti translate
  "形状を移動する"
  (fn [shape dx dy] (::type shape)))

(defmulti scale
  "形状を拡大/縮小する"
  (fn [shape factor] (::type shape)))
