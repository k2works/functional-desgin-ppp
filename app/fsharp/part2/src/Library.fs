namespace FunctionalDesign.Part2

// ============================================
// 第4章: データバリデーション
// ============================================

module Validation =

    // ============================================
    // 1. 基本的なバリデーション（Result を使用）
    // ============================================

    /// バリデーション結果の型エイリアス
    type ValidationResult<'T> = Result<'T, string list>

    /// 名前のバリデーション
    let validateName (name: string) : ValidationResult<string> =
        if System.String.IsNullOrEmpty(name) then
            Error [ "名前は空にできません" ]
        elif name.Length > 100 then
            Error [ "名前は100文字以内である必要があります" ]
        else
            Ok name

    /// 年齢のバリデーション
    let validateAge (age: int) : ValidationResult<int> =
        if age < 0 then
            Error [ "年齢は0以上である必要があります" ]
        elif age > 150 then
            Error [ "年齢は150以下である必要があります" ]
        else
            Ok age

    /// メールアドレスのバリデーション
    let validateEmail (email: string) : ValidationResult<string> =
        let emailRegex = System.Text.RegularExpressions.Regex(@".+@.+\..+")

        if emailRegex.IsMatch(email) then
            Ok email
        else
            Error [ "無効なメールアドレス形式です" ]

    // ============================================
    // 2. 列挙型とスマートコンストラクタ
    // ============================================

    /// 会員種別
    type Membership =
        | Bronze
        | Silver
        | Gold
        | Platinum

    module Membership =
        let fromString (s: string) : ValidationResult<Membership> =
            match s.ToLower() with
            | "bronze" -> Ok Bronze
            | "silver" -> Ok Silver
            | "gold" -> Ok Gold
            | "platinum" -> Ok Platinum
            | _ -> Error [ sprintf "無効な会員種別: %s" s ]

        let toString =
            function
            | Bronze -> "bronze"
            | Silver -> "silver"
            | Gold -> "gold"
            | Platinum -> "platinum"

    /// ステータス
    type Status =
        | Active
        | Inactive
        | Suspended

    // ============================================
    // 3. Validated パターン（エラー蓄積）
    // ============================================

    /// Validated 型（エラー蓄積対応）
    type Validated<'E, 'A> =
        | Valid of 'A
        | Invalid of 'E list

    module Validated =
        let valid a : Validated<'E, 'A> = Valid a
        let invalid errors : Validated<'E, 'A> = Invalid errors

        let map (f: 'A -> 'B) (va: Validated<'E, 'A>) : Validated<'E, 'B> =
            match va with
            | Valid a -> Valid(f a)
            | Invalid errs -> Invalid errs

        let flatMap (f: 'A -> Validated<'E, 'B>) (va: Validated<'E, 'A>) : Validated<'E, 'B> =
            match va with
            | Valid a -> f a
            | Invalid errs -> Invalid errs

        let isValid =
            function
            | Valid _ -> true
            | Invalid _ -> false

        let toResult =
            function
            | Valid a -> Ok a
            | Invalid errs -> Error errs

        /// 2つの Validated を結合（エラー蓄積）
        let combine
            (f: 'A -> 'B -> 'C)
            (va: Validated<'E, 'A>)
            (vb: Validated<'E, 'B>)
            : Validated<'E, 'C> =
            match va, vb with
            | Valid a, Valid b -> Valid(f a b)
            | Invalid e1, Invalid e2 -> Invalid(e1 @ e2) // エラーを蓄積！
            | Invalid e, _ -> Invalid e
            | _, Invalid e -> Invalid e

        /// 3つの Validated を結合
        let combine3
            (f: 'A -> 'B -> 'C -> 'D)
            (va: Validated<'E, 'A>)
            (vb: Validated<'E, 'B>)
            (vc: Validated<'E, 'C>)
            : Validated<'E, 'D> =
            match va, vb, vc with
            | Valid a, Valid b, Valid c -> Valid(f a b c)
            | _ ->
                let errors =
                    [ match va with
                      | Invalid e -> yield! e
                      | _ -> ()
                      match vb with
                      | Invalid e -> yield! e
                      | _ -> ()
                      match vc with
                      | Invalid e -> yield! e
                      | _ -> () ]

                Invalid errors

    // ============================================
    // 4. ドメインプリミティブ（バリデーション付き型）
    // ============================================

    /// 商品ID
    type ProductId = private ProductId of string

    module ProductId =
        let private pattern =
            System.Text.RegularExpressions.Regex(@"^PROD-\d{5}$")

        let create (id: string) : Validated<string, ProductId> =
            if pattern.IsMatch(id) then
                Validated.valid (ProductId id)
            else
                Validated.invalid [ sprintf "無効な商品ID形式: %s (PROD-XXXXXの形式が必要)" id ]

        let value (ProductId id) = id
        let unsafe id = ProductId id

    /// 商品名
    type ProductName = private ProductName of string

    module ProductName =
        let create (name: string) : Validated<string, ProductName> =
            if System.String.IsNullOrEmpty(name) then
                Validated.invalid [ "商品名は空にできません" ]
            elif name.Length > 200 then
                Validated.invalid [ "商品名は200文字以内である必要があります" ]
            else
                Validated.valid (ProductName name)

        let value (ProductName name) = name
        let unsafe name = ProductName name

    /// 価格（正の数）
    type Price = private Price of decimal

    module Price =
        let create (amount: decimal) : Validated<string, Price> =
            if amount <= 0m then
                Validated.invalid [ "価格は正の数である必要があります" ]
            else
                Validated.valid (Price amount)

        let value (Price p) = p
        let unsafe amount = Price amount

    /// 数量（正の整数）
    type Quantity = private Quantity of int

    module Quantity =
        let create (qty: int) : Validated<string, Quantity> =
            if qty <= 0 then
                Validated.invalid [ "数量は正の整数である必要があります" ]
            else
                Validated.valid (Quantity qty)

        let value (Quantity q) = q
        let unsafe qty = Quantity qty

    // ============================================
    // 5. 商品モデル
    // ============================================

    /// 商品
    type Product =
        { Id: ProductId
          Name: ProductName
          Price: Price
          Description: string option
          Category: string option }

    module Product =
        let create
            (id: string)
            (name: string)
            (price: decimal)
            (description: string option)
            (category: string option)
            : Validated<string, Product> =
            Validated.combine3
                (fun pid pname pprice ->
                    { Id = pid
                      Name = pname
                      Price = pprice
                      Description = description
                      Category = category })
                (ProductId.create id)
                (ProductName.create name)
                (Price.create price)

    // ============================================
    // 6. 注文ドメインモデル
    // ============================================

    /// 注文ID
    type OrderId = private OrderId of string

    module OrderId =
        let private pattern =
            System.Text.RegularExpressions.Regex(@"^ORD-\d{8}$")

        let create (id: string) : Validated<string, OrderId> =
            if pattern.IsMatch(id) then
                Validated.valid (OrderId id)
            else
                Validated.invalid [ sprintf "無効な注文ID形式: %s" id ]

        let value (OrderId id) = id
        let unsafe id = OrderId id

    /// 顧客ID
    type CustomerId = private CustomerId of string

    module CustomerId =
        let private pattern =
            System.Text.RegularExpressions.Regex(@"^CUST-\d{6}$")

        let create (id: string) : Validated<string, CustomerId> =
            if pattern.IsMatch(id) then
                Validated.valid (CustomerId id)
            else
                Validated.invalid [ sprintf "無効な顧客ID形式: %s" id ]

        let value (CustomerId id) = id
        let unsafe id = CustomerId id

    /// 注文アイテム
    type OrderItem =
        { ProductId: ProductId
          Quantity: Quantity
          Price: Price }

    module OrderItem =
        let create (productId: string) (quantity: int) (price: decimal) : Validated<string, OrderItem> =
            Validated.combine3
                (fun pid qty pr ->
                    { ProductId = pid
                      Quantity = qty
                      Price = pr })
                (ProductId.create productId)
                (Quantity.create quantity)
                (Price.create price)

        let total (item: OrderItem) =
            Price.value item.Price * decimal (Quantity.value item.Quantity)

    /// 注文
    type Order =
        { OrderId: OrderId
          CustomerId: CustomerId
          Items: OrderItem list
          OrderDate: System.DateTime
          Total: decimal option
          Status: Status option }

    module Order =
        let calculateTotal (order: Order) =
            order.Items |> List.sumBy OrderItem.total

    // ============================================
    // 7. 条件付きバリデーション（ADT）
    // ============================================

    /// 通知タイプ
    type NotificationType =
        | Email
        | SMS
        | Push

    /// 通知（判別共用体による条件付きバリデーション）
    type Notification =
        | EmailNotification of to': string * subject: string * body: string
        | SMSNotification of phoneNumber: string * body: string
        | PushNotification of deviceToken: string * body: string

    module Notification =
        let private emailPattern =
            System.Text.RegularExpressions.Regex(@".+@.+\..+")

        let private phonePattern =
            System.Text.RegularExpressions.Regex(@"\d{2,4}-\d{2,4}-\d{4}")

        let createEmail (to': string) (subject: string) (body: string) : Validated<string, Notification> =
            let errors =
                [ if not (emailPattern.IsMatch(to')) then
                      "無効なメールアドレス形式です"
                  if System.String.IsNullOrEmpty(subject) then
                      "件名は空にできません"
                  if System.String.IsNullOrEmpty(body) then
                      "本文は空にできません" ]

            if errors.IsEmpty then
                Validated.valid (EmailNotification(to', subject, body))
            else
                Validated.invalid errors

        let createSMS (phoneNumber: string) (body: string) : Validated<string, Notification> =
            let errors =
                [ if not (phonePattern.IsMatch(phoneNumber)) then
                      "無効な電話番号形式です"
                  if System.String.IsNullOrEmpty(body) then
                      "本文は空にできません" ]

            if errors.IsEmpty then
                Validated.valid (SMSNotification(phoneNumber, body))
            else
                Validated.invalid errors

        let createPush (deviceToken: string) (body: string) : Validated<string, Notification> =
            let errors =
                [ if System.String.IsNullOrEmpty(deviceToken) then
                      "デバイストークンは空にできません"
                  if System.String.IsNullOrEmpty(body) then
                      "本文は空にできません" ]

            if errors.IsEmpty then
                Validated.valid (PushNotification(deviceToken, body))
            else
                Validated.invalid errors

        let getBody =
            function
            | EmailNotification(_, _, body) -> body
            | SMSNotification(_, body) -> body
            | PushNotification(_, body) -> body

    // ============================================
    // 8. バリデーションユーティリティ
    // ============================================

    /// バリデーションレスポンス
    type ValidationResponse<'T> =
        { Valid: bool
          Data: 'T option
          Errors: string list }

    /// Person
    type Person =
        { Name: string
          Age: int
          Email: string option }

    /// Person のバリデーション
    let validatePerson (name: string) (age: int) (email: string option) : ValidationResponse<Person> =
        let nameV =
            if System.String.IsNullOrEmpty(name) then
                Validated.invalid [ "名前は空にできません" ]
            else
                Validated.valid name

        let ageV =
            if age < 0 then
                Validated.invalid [ "年齢は0以上である必要があります" ]
            else
                Validated.valid age

        let validated =
            Validated.combine
                (fun n a ->
                    { Name = n
                      Age = a
                      Email = email })
                nameV
                ageV

        match validated with
        | Valid p ->
            { Valid = true
              Data = Some p
              Errors = [] }
        | Invalid e ->
            { Valid = false
              Data = None
              Errors = e }

    /// 例外をスローするバリデーション
    let conformOrThrow (validated: Validated<string, 'T>) : 'T =
        match validated with
        | Valid a -> a
        | Invalid errs -> failwithf "Validation failed: %s" (System.String.Join(", ", errs))

    // ============================================
    // 9. 計算関数
    // ============================================

    /// アイテム合計を計算
    let calculateItemTotal (item: OrderItem) =
        Price.value item.Price * decimal (Quantity.value item.Quantity)

    /// 注文合計を計算
    let calculateOrderTotal (order: Order) =
        order.Items |> List.sumBy calculateItemTotal

    /// 割引を適用
    let applyDiscount (total: decimal) (discountRate: float) : Result<decimal, string> =
        if discountRate < 0.0 || discountRate > 1.0 then
            Error "割引率は0から1の間である必要があります"
        else
            Ok(total * (1m - decimal discountRate))

    /// 複数の価格を合計
    let sumPrices (prices: decimal list) : decimal = prices |> List.sum


// ============================================
// 第5章: プロパティベーステスト
// ============================================

module PropertyBasedTesting =

    // ============================================
    // 1. 文字列操作
    // ============================================

    /// 文字列を反転
    let reverseString (s: string) =
        s |> Seq.rev |> System.String.Concat

    /// 大文字に変換
    let toUpperCase (s: string) = s.ToUpperInvariant()

    /// 小文字に変換
    let toLowerCase (s: string) = s.ToLowerInvariant()

    // ============================================
    // 2. 数値操作
    // ============================================

    /// 数値リストをソート
    let sortNumbers (nums: int list) = List.sort nums

    /// 割引を計算
    let calculateDiscount (price: decimal) (rate: float) =
        if rate < 0.0 || rate > 1.0 then
            price
        else
            price * (1m - decimal rate)

    /// 絶対値
    let abs (n: int) = if n < 0 then -n else n

    // ============================================
    // 3. コレクション操作
    // ============================================

    /// フィルタ
    let filter (predicate: 'a -> bool) (list: 'a list) = List.filter predicate list

    /// マップ
    let map (f: 'a -> 'b) (list: 'a list) = List.map f list

    /// 反転
    let reverse (list: 'a list) = List.rev list

    /// 連結
    let concat (list1: 'a list) (list2: 'a list) = list1 @ list2

    /// 重複除去
    let distinct (list: 'a list) = List.distinct list

    // ============================================
    // 4. ランレングス符号化
    // ============================================

    /// ランレングス符号化
    let encode (s: string) : (char * int) list =
        if System.String.IsNullOrEmpty(s) then
            []
        else
            s
            |> Seq.fold
                (fun acc c ->
                    match acc with
                    | [] -> [ (c, 1) ]
                    | (lastChar, count) :: rest when lastChar = c -> (lastChar, count + 1) :: rest
                    | _ -> (c, 1) :: acc)
                []
            |> List.rev

    /// ランレングス復号化
    let decode (encoded: (char * int) list) : string =
        encoded
        |> List.map (fun (c, count) -> System.String(c, count))
        |> System.String.Concat

    // ============================================
    // 5. Base64 エンコード/デコード
    // ============================================

    /// Base64 エンコード
    let base64Encode (s: string) =
        s
        |> System.Text.Encoding.UTF8.GetBytes
        |> System.Convert.ToBase64String

    /// Base64 デコード
    let base64Decode (s: string) =
        s
        |> System.Convert.FromBase64String
        |> System.Text.Encoding.UTF8.GetString

    // ============================================
    // 6. モノイド
    // ============================================

    /// モノイドインターフェース
    type IMonoid<'T> =
        abstract member Empty: 'T
        abstract member Combine: 'T -> 'T -> 'T

    /// 整数加算モノイド
    let intAdditionMonoid =
        { new IMonoid<int> with
            member _.Empty = 0
            member _.Combine x y = x + y }

    /// 文字列連結モノイド
    let stringConcatMonoid =
        { new IMonoid<string> with
            member _.Empty = ""
            member _.Combine x y = x + y }

    /// リスト連結モノイド
    let listConcatMonoid<'T> () =
        { new IMonoid<'T list> with
            member _.Empty = []
            member _.Combine x y = x @ y }

    // ============================================
    // 7. ビジネスロジック
    // ============================================

    /// 会員種別
    type Membership =
        | Bronze
        | Silver
        | Gold
        | Platinum

    /// 会員割引率を取得
    let getMembershipDiscount =
        function
        | Bronze -> 0.02
        | Silver -> 0.05
        | Gold -> 0.10
        | Platinum -> 0.15

    /// 最終価格を計算
    let calculateFinalPrice (total: decimal) (membership: Membership) =
        let discount = getMembershipDiscount membership
        total * (1m - decimal discount)

    // ============================================
    // 8. バリデーション関数
    // ============================================

    /// 有効なメールかどうか
    let isValidEmail (email: string) =
        not (System.String.IsNullOrEmpty(email))
        && email.Contains("@")
        && email.Contains(".")

    /// 有効な電話番号かどうか（数字のみ、10〜15桁）
    let isValidPhoneNumber (phone: string) =
        not (System.String.IsNullOrEmpty(phone))
        && phone.Length >= 10
        && phone.Length <= 15
        && phone |> Seq.forall System.Char.IsDigit


// ============================================
// 第6章: テスト駆動開発と関数型プログラミング
// ============================================

module TddFunctional =

    // ============================================
    // 1. FizzBuzz
    // ============================================

    /// 3で割り切れるかどうか
    let isFizz n = n % 3 = 0

    /// 5で割り切れるかどうか
    let isBuzz n = n % 5 = 0

    /// 15で割り切れるかどうか（FizzBuzz）
    let isFizzBuzz n = isFizz n && isBuzz n

    /// FizzBuzz変換
    let fizzbuzz n =
        if isFizzBuzz n then "FizzBuzz"
        elif isFizz n then "Fizz"
        elif isBuzz n then "Buzz"
        else string n

    /// 1からnまでのFizzBuzz列を生成
    let fizzbuzzSequence n =
        [ 1 .. n ] |> List.map fizzbuzz

    // ============================================
    // 2. ローマ数字変換
    // ============================================

    /// ローマ数字の対応表（大きい順）
    let private romanNumerals =
        [ (1000, "M"); (900, "CM"); (500, "D"); (400, "CD")
          (100, "C");  (90, "XC");  (50, "L");  (40, "XL")
          (10, "X");   (9, "IX");   (5, "V");   (4, "IV")
          (1, "I") ]

    /// 整数をローマ数字に変換
    let toRoman n =
        if n <= 0 || n > 3999 then
            invalidArg "n" "n must be between 1 and 3999"

        let rec loop remaining result =
            if remaining = 0 then
                result
            else
                let (value, numeral) = romanNumerals |> List.find (fun (v, _) -> v <= remaining)
                loop (remaining - value) (result + numeral)

        loop n ""

    /// ローマ数字から整数へ変換（逆変換）
    let private romanValues =
        Map.ofList [ ('I', 1); ('V', 5); ('X', 10); ('L', 50)
                     ('C', 100); ('D', 500); ('M', 1000) ]

    let fromRoman (roman: string) =
        let values = roman |> Seq.map (fun c -> Map.find c romanValues) |> Seq.toList

        let rec loop vals acc =
            match vals with
            | [] -> acc
            | [ x ] -> acc + x
            | x :: y :: rest when x < y -> loop (y :: rest) (acc - x)
            | x :: rest -> loop rest (acc + x)

        loop values 0

    // ============================================
    // 3. ボウリングスコア計算
    // ============================================

    /// ストライクかどうか
    let isStrike rolls =
        match rolls with
        | x :: _ -> x = 10
        | [] -> false

    /// スペアかどうか
    let isSpare rolls =
        match rolls with
        | x :: y :: _ -> x + y = 10 && x <> 10
        | _ -> false

    /// ストライクボーナス
    let strikeBonus remaining =
        remaining |> List.truncate 2 |> List.sum

    /// スペアボーナス
    let spareBonus remaining =
        remaining |> List.tryHead |> Option.defaultValue 0

    /// ボウリングスコアを計算
    let bowlingScore rolls =
        let rec loop remainingRolls frame total =
            if frame > 10 || List.isEmpty remainingRolls then
                total
            elif isStrike remainingRolls then
                loop (List.tail remainingRolls) (frame + 1) (total + 10 + strikeBonus (List.tail remainingRolls))
            elif isSpare remainingRolls then
                loop (remainingRolls |> List.skip 2) (frame + 1) (total + 10 + spareBonus (remainingRolls |> List.skip 2))
            else
                let frameScore = remainingRolls |> List.truncate 2 |> List.sum
                loop (remainingRolls |> List.skip 2) (frame + 1) (total + frameScore)

        loop rolls 1 0

    // ============================================
    // 4. 素数
    // ============================================

    /// 素数判定
    let isPrime n =
        if n < 2 then false
        elif n = 2 then true
        elif n % 2 = 0 then false
        else
            let sqrtN = int (sqrt (float n))
            seq { 3 .. 2 .. sqrtN }
            |> Seq.exists (fun i -> n % i = 0)
            |> not

    /// n以下の素数をすべて返す
    let primesUpTo n =
        [ 2 .. n ] |> List.filter isPrime

    /// 素因数分解
    let primeFactors n =
        let rec loop remaining factor factors =
            if remaining = 1 then
                List.rev factors
            elif remaining % factor = 0 then
                loop (remaining / factor) factor (factor :: factors)
            else
                loop remaining (factor + 1) factors

        loop n 2 []

    // ============================================
    // 5. 不変スタック
    // ============================================

    type Stack<'T> =
        private { Items: 'T list }

        member this.IsEmpty = List.isEmpty this.Items
        member this.Size = List.length this.Items

        member this.Push(item: 'T) = { Items = item :: this.Items }

        member this.Pop() =
            match this.Items with
            | head :: tail -> Some(head, { Items = tail })
            | [] -> None

        member this.Peek() = List.tryHead this.Items

    module Stack =
        let empty<'T> : Stack<'T> = { Items = [] }
        let push item (stack: Stack<'T>) = stack.Push(item)
        let pop (stack: Stack<'T>) = stack.Pop()
        let peek (stack: Stack<'T>) = stack.Peek()
        let isEmpty (stack: Stack<'T>) = stack.IsEmpty
        let size (stack: Stack<'T>) = stack.Size

    // ============================================
    // 6. 不変キュー（2つのリストで実装）
    // ============================================

    type Queue<'T> =
        private { Front: 'T list; Back: 'T list }

        member this.IsEmpty = List.isEmpty this.Front && List.isEmpty this.Back

        member this.Enqueue(item: 'T) = { Front = this.Front; Back = item :: this.Back }

        member this.Dequeue() =
            match this.Front with
            | head :: tail -> Some(head, { Front = tail; Back = this.Back })
            | [] ->
                match List.rev this.Back with
                | head :: tail -> Some(head, { Front = tail; Back = [] })
                | [] -> None

    module Queue =
        let empty<'T> : Queue<'T> = { Front = []; Back = [] }
        let enqueue item (queue: Queue<'T>) = queue.Enqueue(item)
        let dequeue (queue: Queue<'T>) = queue.Dequeue()
        let isEmpty (queue: Queue<'T>) = queue.IsEmpty

    // ============================================
    // 7. 文字列電卓
    // ============================================

    module StringCalculator =
        /// 区切り文字と数値文字列をパース
        let private parseInput (input: string) =
            if input.StartsWith("//") then
                let delimiterEnd = input.IndexOf('\n')
                let delimiter = input.Substring(2, delimiterEnd - 2)
                let numbers = input.Substring(delimiterEnd + 1)
                (delimiter, numbers)
            else
                (",|\n", input)

        /// 数値をパース
        let private parseNumbers (numbers: string) (delimiter: string) =
            let regex = System.Text.RegularExpressions.Regex(delimiter)
            regex.Split(numbers)
            |> Array.filter (fun s -> not (System.String.IsNullOrEmpty(s)))
            |> Array.map int
            |> Array.toList

        /// 負の数をバリデーション
        let private validateNumbers (nums: int list) =
            let negatives = nums |> List.filter (fun n -> n < 0)
            if not (List.isEmpty negatives) then
                let negStr = negatives |> List.map string |> String.concat ", "
                invalidArg "input" (sprintf "negatives not allowed: %s" negStr)

        /// 文字列電卓
        let add (input: string) =
            if System.String.IsNullOrEmpty(input) then
                0
            else
                let (delimiter, numbers) = parseInput input
                let nums = parseNumbers numbers delimiter
                validateNumbers nums
                nums |> List.filter (fun n -> n <= 1000) |> List.sum

    // ============================================
    // 8. 税計算（純粋関数）
    // ============================================

    type Item = { Name: string; Price: decimal }

    type TaxCalculation =
        { Subtotal: decimal
          Tax: decimal
          Total: decimal }

    module TaxCalculator =
        /// 税額を計算
        let calculateTax (amount: decimal) (rate: decimal) = amount * rate

        /// 税込み総額を計算
        let calculateTotalWithTax (items: Item list) (taxRate: decimal) =
            let subtotal = items |> List.sumBy (fun i -> i.Price)
            let tax = calculateTax subtotal taxRate
            { Subtotal = subtotal
              Tax = tax
              Total = subtotal + tax }

    // ============================================
    // 9. 送料計算（データ駆動）
    // ============================================

    type Region =
        | Local
        | Domestic
        | International

    type ShippingOrder =
        { Total: decimal
          Weight: float
          Region: Region }

    module ShippingCalculator =
        let isFreeShipping (total: decimal) = total >= 10000m

        let private shippingRates =
            Map.ofList
                [ (Local, Map.ofList [ (true, 300); (false, 500) ])
                  (Domestic, Map.ofList [ (true, 500); (false, 800) ])
                  (International, Map.ofList [ (true, 2000); (false, 3000) ]) ]

        let calculateShipping (order: ShippingOrder) =
            if isFreeShipping order.Total then
                0
            else
                let isLight = order.Weight < 5.0
                shippingRates
                |> Map.tryFind order.Region
                |> Option.bind (Map.tryFind isLight)
                |> Option.defaultValue 500

    // ============================================
    // 10. パスワードバリデーター
    // ============================================

    module PasswordValidator =
        type Rule = string -> string option

        let minLength (min: int) : Rule =
            fun password ->
                if password.Length >= min then None
                else Some (sprintf "Password must be at least %d characters" min)

        let hasUppercase: Rule =
            fun password ->
                if password |> Seq.exists System.Char.IsUpper then None
                else Some "Password must contain at least one uppercase letter"

        let hasLowercase: Rule =
            fun password ->
                if password |> Seq.exists System.Char.IsLower then None
                else Some "Password must contain at least one lowercase letter"

        let hasDigit: Rule =
            fun password ->
                if password |> Seq.exists System.Char.IsDigit then None
                else Some "Password must contain at least one digit"

        let hasSpecialChar: Rule =
            fun password ->
                let specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
                if password |> Seq.exists (fun c -> specialChars.Contains(c)) then None
                else Some "Password must contain at least one special character"

        let defaultRules: Rule list =
            [ minLength 8; hasUppercase; hasLowercase; hasDigit ]

        let validate (password: string) (rules: Rule list) : Result<string, string list> =
            let errors = rules |> List.choose (fun rule -> rule password)
            if List.isEmpty errors then Ok password
            else Error errors

        let validateWithDefaults (password: string) : Result<string, string list> =
            validate password defaultRules

