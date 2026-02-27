(ns video-rental.statement
  "レンタルビデオシステム - 明細書生成

   テキスト形式とHTML形式の明細書を
   生成します。"
  (:require [video-rental.rental :as rental]
            [video-rental.pricing :as pricing]
            [clojure.string :as str]))

;; =============================================================================
;; フォーマッターマルチメソッド
;; =============================================================================

(defmulti format-statement
  "明細書をフォーマット"
  (fn [format _customer _rentals] format))

;; テキスト形式
(defmethod format-statement :text
  [_ customer rentals]
  (let [header (str "Rental Record for " customer "\n")
        lines (map (fn [r]
                     (str "\t" (rental/get-movie-title r)
                          "\t" (pricing/determine-amount r) "\n"))
                   rentals)
        total (pricing/total-amount rentals)
        points (pricing/total-points rentals)
        footer (str "Amount owed is " total "\n"
                    "You earned " points " frequent renter points")]
    (str header (apply str lines) footer)))

;; HTML形式
(defmethod format-statement :html
  [_ customer rentals]
  (let [header (str "<h1>Rental Record for <em>" customer "</em></h1>\n<ul>\n")
        lines (map (fn [r]
                     (str "  <li>" (rental/get-movie-title r)
                          " - " (pricing/determine-amount r) "</li>\n"))
                   rentals)
        total (pricing/total-amount rentals)
        points (pricing/total-points rentals)
        footer (str "</ul>\n"
                    "<p>Amount owed is <strong>" total "</strong></p>\n"
                    "<p>You earned <strong>" points "</strong> frequent renter points</p>")]
    (str header (apply str lines) footer)))

;; =============================================================================
;; 明細書生成
;; =============================================================================

(defn make-statement
  "明細書を生成（デフォルトはテキスト形式）"
  ([customer rentals]
   (make-statement :text customer rentals))
  ([format customer rentals]
   (format-statement format customer rentals)))

;; =============================================================================
;; 明細データ生成
;; =============================================================================

(defn statement-data
  "明細データを生成（フォーマット非依存）"
  [customer rentals]
  {:customer customer
   :rentals (map (fn [r]
                   {:title (rental/get-movie-title r)
                    :days (rental/get-days r)
                    :amount (pricing/determine-amount r)
                    :points (pricing/determine-points r)})
                 rentals)
   :total-amount (pricing/total-amount rentals)
   :total-points (pricing/total-points rentals)})
