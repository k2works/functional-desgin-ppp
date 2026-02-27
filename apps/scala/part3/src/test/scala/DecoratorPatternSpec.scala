/**
 * 第8章: Decorator パターン - テストコード
 */
package decoratorpattern

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers
import org.scalatest.BeforeAndAfterEach

class DecoratorPatternSpec extends AnyFunSuite with Matchers with BeforeAndAfterEach:
  
  implicit var logCollector: LogCollector = _
  implicit var metricsCollector: MetricsCollector = _
  
  override def beforeEach(): Unit =
    logCollector = new LogCollector
    metricsCollector = new MetricsCollector

  // ============================================
  // 1. JournaledShape のテスト
  // ============================================
  
  test("JournaledShape: translateは操作をジャーナルに記録する") {
    val circle = Circle(0, 0, 5)
    val journaled = JournaledShape(circle).translate(3, 4)
    
    journaled.journal shouldBe List(JournalEntry.Translate(3, 4))
    journaled.shape.asInstanceOf[Circle].centerX shouldBe 3
    journaled.shape.asInstanceOf[Circle].centerY shouldBe 4
  }
  
  test("JournaledShape: scaleは操作をジャーナルに記録する") {
    val square = Square(0, 0, 10)
    val journaled = JournaledShape(square).scale(2)
    
    journaled.journal shouldBe List(JournalEntry.Scale(2))
    journaled.shape.asInstanceOf[Square].side shouldBe 20
  }
  
  test("JournaledShape: 複数の操作が順序通り記録される") {
    val circle = Circle(0, 0, 5)
    val journaled = JournaledShape(circle)
      .translate(1, 2)
      .scale(3)
      .translate(4, 5)
    
    journaled.journal shouldBe List(
      JournalEntry.Translate(1, 2),
      JournalEntry.Scale(3),
      JournalEntry.Translate(4, 5)
    )
  }
  
  test("JournaledShape: areaは内部の形状の面積を返す") {
    val circle = Circle(0, 0, 2)
    val journaled = JournaledShape(circle)
    
    journaled.area shouldBe circle.area
  }
  
  test("JournaledShape: clearJournalはジャーナルをクリアする") {
    val journaled = JournaledShape(Circle(0, 0, 5))
      .translate(1, 2)
      .scale(3)
      .clearJournal
    
    journaled.journal shouldBe empty
  }
  
  test("JournaledShape: replayは操作を再生する") {
    val circle = Circle(0, 0, 5)
    val original = JournaledShape(circle)
      .translate(10, 20)
      .scale(2)
    
    val replayed = JournaledShape(circle).replay(original.journal)
    
    replayed.shape.asInstanceOf[Circle].centerX shouldBe 10
    replayed.shape.asInstanceOf[Circle].centerY shouldBe 20
    replayed.shape.asInstanceOf[Circle].radius shouldBe 10
  }

  // ============================================
  // 2. ログデコレータのテスト
  // ============================================
  
  test("withLogging: 関数呼び出しをログに記録する") {
    val add: Int => Int = _ + 10
    val logged = FunctionDecorators.withLogging(add, "add")
    
    val result = logged(5)
    
    result shouldBe 15
    logCollector.getAll should contain("[add] called with: 5")
    logCollector.getAll should contain("[add] returned: 15")
  }
  
  test("withLogging2: 2引数関数のログを記録する") {
    val multiply: (Int, Int) => Int = _ * _
    val logged = FunctionDecorators.withLogging2(multiply, "multiply")
    
    val result = logged(3, 4)
    
    result shouldBe 12
    logCollector.getAll should contain("[multiply] called with: (3, 4)")
    logCollector.getAll should contain("[multiply] returned: 12")
  }

  // ============================================
  // 3. タイミングデコレータのテスト
  // ============================================
  
  test("withTiming: 関数の実行時間を記録する") {
    val slowFn: Int => Int = { n =>
      Thread.sleep(10)
      n * 2
    }
    val timed = FunctionDecorators.withTiming(slowFn, "slowFn")
    
    val result = timed(5)
    
    result shouldBe 10
    metricsCollector.get("slowFn") should have length 1
    metricsCollector.get("slowFn").head should be >= 10000000L // 10ms in nanoseconds
  }

  // ============================================
  // 4. リトライデコレータのテスト
  // ============================================
  
  test("withRetry: 成功時はそのまま結果を返す") {
    val fn: Int => Int = _ * 2
    val retried = FunctionDecorators.withRetry(fn, 3)
    
    retried(5) shouldBe 10
  }
  
  test("withRetry: 失敗時はリトライする") {
    var attempts = 0
    val fn: Int => Int = { n =>
      attempts += 1
      if attempts < 3 then throw new RuntimeException("Fail")
      else n * 2
    }
    val retried = FunctionDecorators.withRetry(fn, 3)
    
    retried(5) shouldBe 10
    attempts shouldBe 3
  }
  
  test("withRetry: リトライ上限を超えると例外をスローする") {
    val fn: Int => Int = _ => throw new RuntimeException("Always fail")
    val retried = FunctionDecorators.withRetry(fn, 3)
    
    assertThrows[RuntimeException] {
      retried(5)
    }
  }

  // ============================================
  // 5. キャッシュデコレータのテスト
  // ============================================
  
  test("withCache: 同じ入力に対してキャッシュを使用する") {
    var callCount = 0
    val fn: Int => Int = { n =>
      callCount += 1
      n * 2
    }
    val cached = FunctionDecorators.withCache(fn)
    
    cached(5) shouldBe 10
    cached(5) shouldBe 10
    cached(5) shouldBe 10
    callCount shouldBe 1
  }
  
  test("withCache: 異なる入力に対しては毎回計算する") {
    var callCount = 0
    val fn: Int => Int = { n =>
      callCount += 1
      n * 2
    }
    val cached = FunctionDecorators.withCache(fn)
    
    cached(5) shouldBe 10
    cached(6) shouldBe 12
    cached(7) shouldBe 14
    callCount shouldBe 3
  }
  
  test("withTTLCache: TTL後にキャッシュが無効になる") {
    var callCount = 0
    val fn: Int => Int = { n =>
      callCount += 1
      n * 2
    }
    val cached = FunctionDecorators.withTTLCache(fn, 50) // 50ms TTL
    
    cached(5) shouldBe 10
    cached(5) shouldBe 10
    callCount shouldBe 1
    
    Thread.sleep(60)
    
    cached(5) shouldBe 10
    callCount shouldBe 2
  }

  // ============================================
  // 6. バリデーションデコレータのテスト
  // ============================================
  
  test("withValidation: 有効な入力は通過する") {
    val fn: Int => Int = _ * 2
    val validated = FunctionDecorators.withValidation(fn)(_ > 0, "Must be positive")
    
    validated(5) shouldBe 10
  }
  
  test("withValidation: 無効な入力は例外をスローする") {
    val fn: Int => Int = _ * 2
    val validated = FunctionDecorators.withValidation(fn)(_ > 0, "Must be positive")
    
    val exception = intercept[IllegalArgumentException] {
      validated(-5)
    }
    exception.getMessage should include("Must be positive")
  }
  
  test("withPostCondition: 有効な出力は通過する") {
    val fn: Int => Int = _ * 2
    val validated = FunctionDecorators.withPostCondition(fn)(_ > 0, "Result must be positive")
    
    validated(5) shouldBe 10
  }
  
  test("withPostCondition: 無効な出力は例外をスローする") {
    val fn: Int => Int = _ * 2
    val validated = FunctionDecorators.withPostCondition(fn)(_ > 0, "Result must be positive")
    
    assertThrows[IllegalStateException] {
      validated(-5)
    }
  }

  // ============================================
  // 7. エラーハンドリングデコレータのテスト
  // ============================================
  
  test("withOptionResult: 成功時はSomeを返す") {
    val fn: Int => Int = _ * 2
    val optional = FunctionDecorators.withOptionResult(fn)
    
    optional(5) shouldBe Some(10)
  }
  
  test("withOptionResult: 失敗時はNoneを返す") {
    val fn: Int => Int = _ => throw new RuntimeException("Fail")
    val optional = FunctionDecorators.withOptionResult(fn)
    
    optional(5) shouldBe None
  }
  
  test("withEitherResult: 成功時はRightを返す") {
    val fn: Int => Int = _ * 2
    val either = FunctionDecorators.withEitherResult(fn)
    
    either(5) shouldBe Right(10)
  }
  
  test("withEitherResult: 失敗時はLeftを返す") {
    val fn: Int => Int = _ => throw new RuntimeException("Fail")
    val either = FunctionDecorators.withEitherResult(fn)
    
    either(5).isLeft shouldBe true
  }
  
  test("withDefault: 成功時は結果を返す") {
    val fn: Int => Int = _ * 2
    val withDefault = FunctionDecorators.withDefault(fn, 0)
    
    withDefault(5) shouldBe 10
  }
  
  test("withDefault: 失敗時はデフォルト値を返す") {
    val fn: Int => Int = _ => throw new RuntimeException("Fail")
    val withDefault = FunctionDecorators.withDefault(fn, 0)
    
    withDefault(5) shouldBe 0
  }

  // ============================================
  // 8. デコレータの合成のテスト
  // ============================================
  
  test("compose: 複数のデコレータを合成できる") {
    val fn: Int => Int = _ * 2
    
    val decorators: List[(Int => Int) => (Int => Int)] = List(
      f => FunctionDecorators.withCache(f),
      f => FunctionDecorators.withLogging(f, "fn")
    )
    
    val composed = DecoratorComposition.compose(fn, decorators)
    
    composed(5) shouldBe 10
    logCollector.getAll should contain("[fn] called with: 5")
  }

  // ============================================
  // 9. AuditedList のテスト
  // ============================================
  
  test("AuditedList: addは操作を記録する") {
    val list = AuditedList.empty[Int].add(1).add(2).add(3)
    
    list.items shouldBe List(1, 2, 3)
    list.operations shouldBe List("add(1)", "add(2)", "add(3)")
  }
  
  test("AuditedList: removeは操作を記録する") {
    val list = AuditedList(1, 2, 3).remove(2)
    
    list.items shouldBe List(1, 3)
    list.operations should contain("remove(2)")
  }
  
  test("AuditedList: mapは操作を記録する") {
    val list = AuditedList(1, 2, 3).map(_ * 2)
    
    list.items shouldBe List(2, 4, 6)
    list.operations should contain("map")
  }
  
  test("AuditedList: filterは操作を記録する") {
    val list = AuditedList(1, 2, 3, 4, 5).filter(_ % 2 == 0)
    
    list.items shouldBe List(2, 4)
    list.operations should contain("filter")
  }

  // ============================================
  // 10. HTTPクライアントデコレータのテスト
  // ============================================
  
  test("LoggingHttpClient: リクエストをログに記録する") {
    val client = new LoggingHttpClient(new SimpleHttpClient)
    
    val response = client.get("http://example.com")
    
    response.status shouldBe 200
    logCollector.getAll should contain("[HTTP] GET http://example.com")
    logCollector.getAll should contain("[HTTP] Response: 200")
  }
  
  test("CachingHttpClient: 同じURLに対してキャッシュを使用する") {
    var callCount = 0
    val baseClient = new HttpClient:
      def get(url: String): HttpResponse =
        callCount += 1
        HttpResponse(200, s"Response $callCount")
    
    val client = new CachingHttpClient(baseClient)
    
    client.get("http://example.com")
    client.get("http://example.com")
    client.get("http://example.com")
    
    callCount shouldBe 1
  }
  
  test("HTTPクライアント: デコレータを組み合わせられる") {
    val client = new LoggingHttpClient(
      new CachingHttpClient(
        new SimpleHttpClient
      )
    )
    
    val response = client.get("http://example.com")
    
    response.status shouldBe 200
    logCollector.getAll should contain("[HTTP] GET http://example.com")
  }

  // ============================================
  // 11. FunctionBuilder のテスト
  // ============================================
  
  test("FunctionBuilder: デコレータをビルダースタイルで適用できる") {
    val fn = FunctionBuilder[Int, Int](_ * 2)
      .withLogging("double")
      .withCache()
      .withValidation(_ > 0, "Must be positive")
      .build
    
    fn(5) shouldBe 10
    logCollector.getAll should contain("[double] called with: 5")
  }
  
  test("FunctionBuilder: withDefaultはエラー時にデフォルト値を返す") {
    val fn = FunctionBuilder[Int, Int] { n =>
      if n < 0 then throw new RuntimeException("Negative")
      else n * 2
    }.withDefault(0).build
    
    fn(5) shouldBe 10
    fn(-5) shouldBe 0
  }

  // ============================================
  // 12. StreamDecorators のテスト
  // ============================================
  
  test("StreamDecorators: withFilterはストリームをフィルタする") {
    val stream = LazyList(1, 2, 3, 4, 5)
    val filtered = StreamDecorators.withFilter[Int](_ % 2 == 0)(stream)
    
    filtered.toList shouldBe List(2, 4)
  }
  
  test("StreamDecorators: withMapはストリームを変換する") {
    val stream = LazyList(1, 2, 3)
    val mapped = StreamDecorators.withMap[Int, Int](_ * 2)(stream)
    
    mapped.toList shouldBe List(2, 4, 6)
  }
  
  test("StreamDecorators: withTakeは指定数の要素を取得する") {
    val stream = LazyList.from(1)
    val taken = StreamDecorators.withTake[Int](5)(stream)
    
    taken.toList shouldBe List(1, 2, 3, 4, 5)
  }
  
  test("StreamDecorators: withStreamLoggingは処理をログに記録する") {
    val stream = LazyList(1, 2, 3)
    val logged = StreamDecorators.withStreamLogging[Int]("stream")(using logCollector)(stream)
    
    logged.toList // 評価をトリガー
    
    logCollector.getAll should contain("[stream] processing: 1")
    logCollector.getAll should contain("[stream] processing: 2")
    logCollector.getAll should contain("[stream] processing: 3")
  }
