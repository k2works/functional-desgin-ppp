(ns abstract-server.repository-spec
  (:require [speclj.core :refer :all]
            [abstract-server.repository :as repo]
            [abstract-server.memory-repository :as mem-repo]
            [abstract-server.user-service :as user-svc]))

(describe "Abstract Server パターン - Repository"

  (context "MemoryRepository"
    (it "リポジトリを作成できる"
      (let [r (mem-repo/make)]
        (should (empty? (repo/find-all r)))))

    (it "エンティティを保存できる"
      (let [r (mem-repo/make)
            entity (repo/save r {:name "Test"})]
        (should (:id entity))
        (should= "Test" (:name entity))))

    (it "IDでエンティティを取得できる"
      (let [r (mem-repo/make)
            saved (repo/save r {:name "Test"})
            found (repo/find-by-id r (:id saved))]
        (should= saved found)))

    (it "全てのエンティティを取得できる"
      (let [r (mem-repo/make)
            _ (repo/save r {:name "Entity 1"})
            _ (repo/save r {:name "Entity 2"})]
        (should= 2 (count (repo/find-all r)))))

    (it "エンティティを削除できる"
      (let [r (mem-repo/make)
            saved (repo/save r {:name "Test"})
            deleted (repo/delete r (:id saved))]
        (should= saved deleted)
        (should-be-nil (repo/find-by-id r (:id saved)))))

    (it "初期データ付きで作成できる"
      (let [initial [{:id "1" :name "User 1"}
                     {:id "2" :name "User 2"}]
            r (mem-repo/make-with-data initial)]
        (should= 2 (count (repo/find-all r)))
        (should= "User 1" (:name (repo/find-by-id r "1"))))))

  (context "UserService（抽象に依存）"
    (it "ユーザーを作成できる"
      (let [r (mem-repo/make)
            user (user-svc/create-user r "John" "john@example.com")]
        (should (:id user))
        (should= "John" (:name user))
        (should= "john@example.com" (:email user))))

    (it "ユーザーを取得できる"
      (let [r (mem-repo/make)
            created (user-svc/create-user r "John" "john@example.com")
            found (user-svc/get-user r (:id created))]
        (should= created found)))

    (it "全ユーザーを取得できる"
      (let [r (mem-repo/make)
            _ (user-svc/create-user r "John" "john@example.com")
            _ (user-svc/create-user r "Jane" "jane@example.com")
            users (user-svc/get-all-users r)]
        (should= 2 (count users))))

    (it "ユーザーを更新できる"
      (let [r (mem-repo/make)
            created (user-svc/create-user r "John" "john@example.com")
            updated (user-svc/update-user r (:id created) {:name "Johnny"})]
        (should= "Johnny" (:name updated))
        (should= "john@example.com" (:email updated))))

    (it "ユーザーを削除できる"
      (let [r (mem-repo/make)
            created (user-svc/create-user r "John" "john@example.com")
            deleted (user-svc/delete-user r (:id created))]
        (should= created deleted)
        (should-be-nil (user-svc/get-user r (:id created)))))

    (it "メールアドレスでユーザーを検索できる"
      (let [r (mem-repo/make)
            _ (user-svc/create-user r "John" "john@example.com")
            _ (user-svc/create-user r "Jane" "jane@example.com")
            found (user-svc/find-by-email r "john@example.com")]
        (should= "John" (:name found))))))

(run-specs)
