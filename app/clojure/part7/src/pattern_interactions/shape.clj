(ns pattern-interactions.shape
  "図形の基本インターフェース - Composite パターンの基盤")

;; マルチメソッドによる図形操作
(defmulti move
  "図形を移動"
  (fn [shape _dx _dy] (:type shape)))

(defmulti scale
  "図形を拡大/縮小"
  (fn [shape _factor] (:type shape)))

(defmulti draw
  "図形を描画（文字列表現）"
  :type)

(defmulti area
  "図形の面積を計算"
  :type)

;; 円
(defn make-circle
  "円を作成"
  [x y radius]
  {:type :circle
   :x x
   :y y
   :radius radius})

(defmethod move :circle
  [shape dx dy]
  (-> shape
      (update :x + dx)
      (update :y + dy)))

(defmethod scale :circle
  [shape factor]
  (update shape :radius * factor))

(defmethod draw :circle
  [shape]
  (str "Circle at (" (:x shape) ", " (:y shape) ") with radius " (:radius shape)))

(defmethod area :circle
  [shape]
  (* Math/PI (:radius shape) (:radius shape)))

;; 矩形
(defn make-rectangle
  "矩形を作成"
  [x y width height]
  {:type :rectangle
   :x x
   :y y
   :width width
   :height height})

(defmethod move :rectangle
  [shape dx dy]
  (-> shape
      (update :x + dx)
      (update :y + dy)))

(defmethod scale :rectangle
  [shape factor]
  (-> shape
      (update :width * factor)
      (update :height * factor)))

(defmethod draw :rectangle
  [shape]
  (str "Rectangle at (" (:x shape) ", " (:y shape) ") "
       "with size " (:width shape) "x" (:height shape)))

(defmethod area :rectangle
  [shape]
  (* (:width shape) (:height shape)))
