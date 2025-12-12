(ns pattern-interactions.decorated-shape
  "装飾付き図形 - Decorator パターン
   Composite と組み合わせて使用"
  (:require [pattern-interactions.shape :as shape]))

;; ジャーナル付き図形（操作履歴を記録）
(defn make-journaled
  "ジャーナル付き図形を作成"
  [s]
  {:type :journaled
   :shape s
   :journal []})

(defn get-journal
  "ジャーナルを取得"
  [decorated]
  (:journal decorated))

(defn- add-journal-entry
  "ジャーナルにエントリを追加"
  [decorated operation]
  (update decorated :journal conj
          {:operation operation
           :timestamp (System/currentTimeMillis)}))

(defmethod shape/move :journaled
  [decorated dx dy]
  (-> decorated
      (update :shape #(shape/move % dx dy))
      (add-journal-entry (str "move(" dx ", " dy ")"))))

(defmethod shape/scale :journaled
  [decorated factor]
  (-> decorated
      (update :shape #(shape/scale % factor))
      (add-journal-entry (str "scale(" factor ")"))))

(defmethod shape/draw :journaled
  [decorated]
  (str "[Journaled: " (count (:journal decorated)) " ops] "
       (shape/draw (:shape decorated))))

(defmethod shape/area :journaled
  [decorated]
  (shape/area (:shape decorated)))

;; 色付き図形
(defn make-colored
  "色付き図形を作成"
  [s color]
  {:type :colored
   :shape s
   :color color})

(defn get-color
  "色を取得"
  [decorated]
  (:color decorated))

(defmethod shape/move :colored
  [decorated dx dy]
  (update decorated :shape #(shape/move % dx dy)))

(defmethod shape/scale :colored
  [decorated factor]
  (update decorated :shape #(shape/scale % factor)))

(defmethod shape/draw :colored
  [decorated]
  (str "[" (:color decorated) "] " (shape/draw (:shape decorated))))

(defmethod shape/area :colored
  [decorated]
  (shape/area (:shape decorated)))

;; 境界線付き図形
(defn make-bordered
  "境界線付き図形を作成"
  [s border-width]
  {:type :bordered
   :shape s
   :border-width border-width})

(defn get-border-width
  "境界線幅を取得"
  [decorated]
  (:border-width decorated))

(defmethod shape/move :bordered
  [decorated dx dy]
  (update decorated :shape #(shape/move % dx dy)))

(defmethod shape/scale :bordered
  [decorated factor]
  (-> decorated
      (update :shape #(shape/scale % factor))
      (update :border-width * factor)))

(defmethod shape/draw :bordered
  [decorated]
  (str "[Border: " (:border-width decorated) "px] "
       (shape/draw (:shape decorated))))

(defmethod shape/area :bordered
  [decorated]
  (shape/area (:shape decorated)))
