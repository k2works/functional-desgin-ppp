(ns adapter-pattern.data-format-spec
  (:require [speclj.core :refer :all]
            [adapter-pattern.data-format :as df]))

(describe "Adapter パターン - データフォーマットアダプター"

  (context "ユーザーフォーマット変換"
    (it "旧フォーマットを新フォーマットに変換できる"
      (let [old-user {:firstName "太郎"
                      :lastName "山田"
                      :emailAddress "taro@example.com"
                      :phoneNumber "090-1234-5678"}
            new-user (df/adapt-old-user-to-new old-user)]
        (should= "山田 太郎" (:name new-user))
        (should= "taro@example.com" (:email new-user))
        (should= "090-1234-5678" (:phone new-user))
        (should (:migrated (:metadata new-user)))))

    (it "新フォーマットを旧フォーマットに変換できる"
      (let [new-user {:name "山田 太郎"
                      :email "taro@example.com"
                      :phone "090-1234-5678"}
            old-user (df/adapt-new-user-to-old new-user)]
        (should= "太郎" (:firstName old-user))
        (should= "山田" (:lastName old-user))
        (should= "taro@example.com" (:emailAddress old-user))
        (should= "090-1234-5678" (:phoneNumber old-user))))

    (it "名前が一つの単語の場合も処理できる"
      (let [new-user {:name "山田"
                      :email "test@example.com"
                      :phone ""}
            old-user (df/adapt-new-user-to-old new-user)]
        (should= "" (:firstName old-user))
        (should= "山田" (:lastName old-user)))))

  (context "API レスポンスアダプター"
    (it "外部API レスポンスを内部形式に変換できる"
      (let [external {"data" {"identifier" "ext-123"
                              "id" "original-id"
                              "attributes" {"name" "Test Item"
                                            "createdAt" "2024-01-01"}}}
            internal (df/adapt-external-api-response external)]
        (should= "ext-123" (:id internal))
        (should= "Test Item" (:name internal))
        (should= "2024-01-01" (:created-at internal))
        (should= :external-api (get-in internal [:metadata :source]))))

    (it "内部形式を外部API 形式に変換できる"
      (let [internal {:id 123
                      :name "Test"
                      :created-at "2024-01-01"}
            external (df/adapt-internal-to-external internal)]
        (should= "123" (get-in external ["data" "id"]))
        (should= "Test" (get-in external ["data" "attributes" "name"]))
        (should= "resource" (get-in external ["data" "type"]))))))

(run-specs)
