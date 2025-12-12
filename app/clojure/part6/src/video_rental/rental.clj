(ns video-rental.rental
  "レンタルビデオシステム - レンタルモデル

   レンタル情報（映画、日数）を管理します。"
  (:require [video-rental.movie :as movie]))

;; =============================================================================
;; コンストラクタ
;; =============================================================================

(defn make-rental
  "レンタルを作成"
  [movie days]
  {:movie movie
   :days days})

;; =============================================================================
;; アクセサ
;; =============================================================================

(defn get-movie [rental]
  (:movie rental))

(defn get-days [rental]
  (:days rental))

(defn get-movie-title [rental]
  (movie/get-title (:movie rental)))

(defn get-movie-category [rental]
  (movie/get-category (:movie rental)))
