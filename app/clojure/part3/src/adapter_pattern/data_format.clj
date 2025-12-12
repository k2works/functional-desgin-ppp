(ns adapter-pattern.data-format
  "Adapter パターン - データフォーマットアダプター

   異なるデータフォーマット間の変換を行うアダプターの例です。
   旧形式のユーザーデータを新形式に変換します。"
  (:require [clojure.string :as str]))

;; =============================================================================
;; ユーザーフォーマットアダプター
;; =============================================================================

(defn adapt-old-user-to-new
  "旧ユーザーフォーマットを新フォーマットに変換"
  [old-user]
  {:name (str (:lastName old-user) " " (:firstName old-user))
   :email (:emailAddress old-user)
   :phone (:phoneNumber old-user)
   :metadata {:migrated true
              :original-format :old}})

(defn adapt-new-user-to-old
  "新ユーザーフォーマットを旧フォーマットに変換"
  [new-user]
  (let [name-parts (str/split (:name new-user) #" ")
        last-name (first name-parts)
        first-name (if (> (count name-parts) 1)
                     (second name-parts)
                     "")]
    {:firstName first-name
     :lastName last-name
     :emailAddress (:email new-user)
     :phoneNumber (:phone new-user)}))

;; =============================================================================
;; API レスポンスアダプター
;; =============================================================================

(defn adapt-external-api-response
  "外部API のレスポンスを内部形式に変換"
  [external-response]
  {:id (get-in external-response ["data" "identifier"])
   :name (get-in external-response ["data" "attributes" "name"])
   :created-at (get-in external-response ["data" "attributes" "createdAt"])
   :metadata {:source :external-api
              :original-id (get-in external-response ["data" "id"])}})

(defn adapt-internal-to-external
  "内部形式を外部API の形式に変換"
  [internal-data]
  {"data" {"type" "resource"
           "id" (str (:id internal-data))
           "attributes" {"name" (:name internal-data)
                         "createdAt" (:created-at internal-data)}}})
