(ns adapter-pattern.variable-light-adapter
  "Adapter パターン - VariableLightAdapter (Adapter)

   VariableLight（可変強度ライト）を Switchable インターフェース
   （単純なオン/オフ）に適応させるアダプターです。"
  (:require [adapter-pattern.switchable :as s]
            [adapter-pattern.variable-light :as vl]))

(defn make-adapter
  "VariableLight のアダプターを作成する"
  [min-intensity max-intensity]
  {:type :variable-light-adapter
   :min-intensity min-intensity
   :max-intensity max-intensity})

(defmethod s/turn-on :variable-light-adapter [adapter]
  (vl/turn-on-light (:max-intensity adapter)))

(defmethod s/turn-off :variable-light-adapter [adapter]
  (vl/turn-on-light (:min-intensity adapter)))
