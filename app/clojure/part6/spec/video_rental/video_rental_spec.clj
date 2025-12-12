(ns video-rental.video-rental-spec
  (:require [speclj.core :refer :all]
            [video-rental.movie :as movie]
            [video-rental.rental :as rental]
            [video-rental.pricing :as pricing]
            [video-rental.statement :as stmt]))

(describe "レンタルビデオシステム"

  (context "映画の作成"
    (it "通常映画を作成できる"
      (let [m (movie/make-regular "Inception")]
        (should= "Inception" (movie/get-title m))
        (should= :regular (movie/get-category m))))

    (it "新作映画を作成できる"
      (let [m (movie/make-new-release "New Movie")]
        (should= :new-release (movie/get-category m))))

    (it "子供向け映画を作成できる"
      (let [m (movie/make-childrens "Frozen")]
        (should= :childrens (movie/get-category m)))))

  (context "レンタルの作成"
    (it "映画と日数でレンタルを作成できる"
      (let [m (movie/make-regular "Test")
            r (rental/make-rental m 3)]
        (should= "Test" (rental/get-movie-title r))
        (should= 3 (rental/get-days r))
        (should= :regular (rental/get-movie-category r)))))

  (context "料金計算 - 通常映画"
    (it "2日以下は2.0"
      (let [m (movie/make-regular "Test")
            r1 (rental/make-rental m 1)
            r2 (rental/make-rental m 2)]
        (should= 2.0 (pricing/determine-amount r1))
        (should= 2.0 (pricing/determine-amount r2))))

    (it "3日以上は追加料金"
      (let [m (movie/make-regular "Test")
            r3 (rental/make-rental m 3)
            r5 (rental/make-rental m 5)]
        (should= 3.5 (pricing/determine-amount r3))  ; 2.0 + 1.5
        (should= 6.5 (pricing/determine-amount r5))))) ; 2.0 + 4.5

  (context "料金計算 - 新作"
    (it "1日ごとに3.0"
      (let [m (movie/make-new-release "New")
            r1 (rental/make-rental m 1)
            r3 (rental/make-rental m 3)]
        (should= 3.0 (pricing/determine-amount r1))
        (should= 9.0 (pricing/determine-amount r3)))))

  (context "料金計算 - 子供向け"
    (it "3日以下は1.5"
      (let [m (movie/make-childrens "Kids")
            r1 (rental/make-rental m 1)
            r3 (rental/make-rental m 3)]
        (should= 1.5 (pricing/determine-amount r1))
        (should= 1.5 (pricing/determine-amount r3))))

    (it "4日以上は追加料金"
      (let [m (movie/make-childrens "Kids")
            r4 (rental/make-rental m 4)
            r6 (rental/make-rental m 6)]
        (should= 3.0 (pricing/determine-amount r4))  ; 1.5 + 1.5
        (should= 6.0 (pricing/determine-amount r6))))) ; 1.5 + 4.5

  (context "ポイント計算"
    (it "通常映画は1ポイント"
      (let [m (movie/make-regular "Test")
            r (rental/make-rental m 5)]
        (should= 1 (pricing/determine-points r))))

    (it "新作は2日以上で2ポイント"
      (let [m (movie/make-new-release "New")
            r1 (rental/make-rental m 1)
            r2 (rental/make-rental m 2)]
        (should= 1 (pricing/determine-points r1))
        (should= 2 (pricing/determine-points r2))))

    (it "子供向けは1ポイント"
      (let [m (movie/make-childrens "Kids")
            r (rental/make-rental m 5)]
        (should= 1 (pricing/determine-points r)))))

  (context "合計計算"
    (it "複数レンタルの合計金額を計算"
      (let [rentals [(rental/make-rental (movie/make-regular "R") 3)
                     (rental/make-rental (movie/make-new-release "N") 2)
                     (rental/make-rental (movie/make-childrens "C") 4)]]
        ;; 3.5 + 6.0 + 3.0 = 12.5
        (should= 12.5 (pricing/total-amount rentals))))

    (it "複数レンタルの合計ポイントを計算"
      (let [rentals [(rental/make-rental (movie/make-regular "R") 3)
                     (rental/make-rental (movie/make-new-release "N") 2)
                     (rental/make-rental (movie/make-childrens "C") 4)]]
        ;; 1 + 2 + 1 = 4
        (should= 4 (pricing/total-points rentals)))))

  (context "明細書 - テキスト形式"
    (it "テキスト形式の明細書を生成"
      (let [rentals [(rental/make-rental (movie/make-regular "Inception") 3)]
            statement (stmt/make-statement "John" rentals)]
        (should-contain "Rental Record for John" statement)
        (should-contain "Inception" statement)
        (should-contain "3.5" statement)
        (should-contain "Amount owed is 3.5" statement)
        (should-contain "1 frequent renter points" statement))))

  (context "明細書 - HTML形式"
    (it "HTML形式の明細書を生成"
      (let [rentals [(rental/make-rental (movie/make-regular "Inception") 3)]
            statement (stmt/make-statement :html "John" rentals)]
        (should-contain "<h1>Rental Record for <em>John</em></h1>" statement)
        (should-contain "<li>Inception - 3.5</li>" statement)
        (should-contain "<strong>3.5</strong>" statement))))

  (context "明細データ"
    (it "フォーマット非依存の明細データを生成"
      (let [rentals [(rental/make-rental (movie/make-regular "R") 3)
                     (rental/make-rental (movie/make-new-release "N") 2)]
            data (stmt/statement-data "John" rentals)]
        (should= "John" (:customer data))
        (should= 2 (count (:rentals data)))
        (should= 9.5 (:total-amount data))  ; 3.5 + 6.0
        (should= 3 (:total-points data)))))) ; 1 + 2

(run-specs)
