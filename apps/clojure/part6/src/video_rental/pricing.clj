(ns video-rental.pricing
  "レンタルビデオシステム - 料金計算

   各映画カテゴリに応じた料金計算ロジックを
   マルチメソッドで実装します。"
  (:require [video-rental.rental :as rental]))

;; =============================================================================
;; 料金計算マルチメソッド
;; =============================================================================

(defmulti determine-amount
  "レンタル料金を計算"
  (fn [r] (rental/get-movie-category r)))

;; 通常映画: 2日まで2.0、以降1日ごとに1.5追加
(defmethod determine-amount :regular
  [r]
  (let [days (rental/get-days r)]
    (if (> days 2)
      (+ 2.0 (* (- days 2) 1.5))
      2.0)))

;; 新作: 1日ごとに3.0
(defmethod determine-amount :new-release
  [r]
  (* (rental/get-days r) 3.0))

;; 子供向け: 3日まで1.5、以降1日ごとに1.5追加
(defmethod determine-amount :childrens
  [r]
  (let [days (rental/get-days r)]
    (if (> days 3)
      (+ 1.5 (* (- days 3) 1.5))
      1.5)))

;; =============================================================================
;; ポイント計算マルチメソッド
;; =============================================================================

(defmulti determine-points
  "レンタルポイントを計算"
  (fn [r] (rental/get-movie-category r)))

;; 通常映画: 1ポイント
(defmethod determine-points :regular
  [_r]
  1)

;; 新作: 2日以上で2ポイント、それ以外は1ポイント
(defmethod determine-points :new-release
  [r]
  (if (> (rental/get-days r) 1)
    2
    1))

;; 子供向け: 1ポイント
(defmethod determine-points :childrens
  [_r]
  1)

;; =============================================================================
;; 合計計算
;; =============================================================================

(defn total-amount
  "複数レンタルの合計金額を計算"
  [rentals]
  (reduce + 0 (map determine-amount rentals)))

(defn total-points
  "複数レンタルの合計ポイントを計算"
  [rentals]
  (reduce + 0 (map determine-points rentals)))
