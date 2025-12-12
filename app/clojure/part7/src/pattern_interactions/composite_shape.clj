(ns pattern-interactions.composite-shape
  "複合図形 - Composite パターン"
  (:require [pattern-interactions.shape :as shape]))

(defn make-composite
  "複合図形を作成"
  ([] (make-composite []))
  ([shapes]
   {:type :composite
    :shapes shapes}))

(defn add-shape
  "複合図形に図形を追加"
  [composite s]
  (update composite :shapes conj s))

(defn remove-shape
  "複合図形から図形を削除"
  [composite s]
  (update composite :shapes (fn [shapes] (remove #(= % s) shapes))))

(defmethod shape/move :composite
  [composite dx dy]
  (update composite :shapes
          (fn [shapes]
            (mapv #(shape/move % dx dy) shapes))))

(defmethod shape/scale :composite
  [composite factor]
  (update composite :shapes
          (fn [shapes]
            (mapv #(shape/scale % factor) shapes))))

(defmethod shape/draw :composite
  [composite]
  (let [drawings (map shape/draw (:shapes composite))]
    (str "Composite[\n  " (clojure.string/join "\n  " drawings) "\n]")))

(defmethod shape/area :composite
  [composite]
  (reduce + 0 (map shape/area (:shapes composite))))
