/**
 * 第8章: Decorator パターン
 * 
 * Decorator パターンは、既存のオブジェクトに新しい機能を動的に追加するパターンです。
 * 関数型プログラミングでは、高階関数を使って関数をラップし、横断的関心事を追加します。
 */
package decoratorpattern

import scala.util.{Try, Success, Failure}
import java.time.{LocalDateTime, Duration}
import scala.collection.mutable

// ============================================
// 1. JournaledShape - 形状デコレータ
// ============================================

/** ジャーナルエントリ */
enum JournalEntry:
  case Translate(dx: Double, dy: Double)
  case Scale(factor: Double)
  case Rotate(angle: Double)

/** 図形の共通インターフェース */
trait Shape:
  def translate(dx: Double, dy: Double): Shape
  def scale(factor: Double): Shape
  def area: Double

/** 円（基本形状） */
case class Circle(centerX: Double, centerY: Double, radius: Double) extends Shape:
  def translate(dx: Double, dy: Double): Circle =
    copy(centerX = centerX + dx, centerY = centerY + dy)
  def scale(factor: Double): Circle = copy(radius = radius * factor)
  def area: Double = math.Pi * radius * radius

/** 正方形（基本形状） */
case class Square(x: Double, y: Double, side: Double) extends Shape:
  def translate(dx: Double, dy: Double): Square =
    copy(x = x + dx, y = y + dy)
  def scale(factor: Double): Square = copy(side = side * factor)
  def area: Double = side * side

/** ジャーナル付き形状（デコレータ） */
case class JournaledShape(
  shape: Shape,
  journal: List[JournalEntry] = Nil
) extends Shape:
  
  def translate(dx: Double, dy: Double): JournaledShape =
    copy(
      shape = shape.translate(dx, dy),
      journal = journal :+ JournalEntry.Translate(dx, dy)
    )
  
  def scale(factor: Double): JournaledShape =
    copy(
      shape = shape.scale(factor),
      journal = journal :+ JournalEntry.Scale(factor)
    )
  
  def area: Double = shape.area
  
  /** ジャーナルをクリア */
  def clearJournal: JournaledShape = copy(journal = Nil)
  
  /** 操作を再生 */
  def replay(entries: List[JournalEntry]): JournaledShape =
    entries.foldLeft(this) { (js, entry) =>
      entry match
        case JournalEntry.Translate(dx, dy) => js.translate(dx, dy)
        case JournalEntry.Scale(factor) => js.scale(factor)
        case JournalEntry.Rotate(_) => js // 現在は無視
    }

object JournaledShape:
  def apply(shape: Shape): JournaledShape = new JournaledShape(shape)

// ============================================
// 2. 関数デコレータ - 高階関数によるデコレーション
// ============================================

object FunctionDecorators:
  
  // ----------------------------------------
  // ログデコレータ
  // ----------------------------------------
  
  /** 関数にログ出力を追加するデコレータ */
  def withLogging[A, B](f: A => B, name: String)(implicit log: LogCollector): A => B =
    (a: A) =>
      log.add(s"[$name] called with: $a")
      val result = f(a)
      log.add(s"[$name] returned: $result")
      result
  
  /** 2引数関数用のログデコレータ */
  def withLogging2[A, B, C](f: (A, B) => C, name: String)(implicit log: LogCollector): (A, B) => C =
    (a: A, b: B) =>
      log.add(s"[$name] called with: ($a, $b)")
      val result = f(a, b)
      log.add(s"[$name] returned: $result")
      result
  
  // ----------------------------------------
  // タイミングデコレータ
  // ----------------------------------------
  
  /** 関数の実行時間を計測するデコレータ */
  def withTiming[A, B](f: A => B, name: String)(implicit metrics: MetricsCollector): A => B =
    (a: A) =>
      val start = System.nanoTime()
      val result = f(a)
      val elapsed = System.nanoTime() - start
      metrics.record(name, elapsed)
      result
  
  // ----------------------------------------
  // リトライデコレータ
  // ----------------------------------------
  
  /** 関数にリトライ機能を追加するデコレータ */
  def withRetry[A, B](f: A => B, maxRetries: Int, delay: Long = 0): A => B =
    (a: A) =>
      def attempt(remaining: Int): B =
        Try(f(a)) match
          case Success(result) => result
          case Failure(e) if remaining > 0 =>
            if delay > 0 then Thread.sleep(delay)
            attempt(remaining - 1)
          case Failure(e) => throw e
      attempt(maxRetries)
  
  // ----------------------------------------
  // キャッシュデコレータ
  // ----------------------------------------
  
  /** 関数にキャッシュを追加するデコレータ */
  def withCache[A, B](f: A => B): A => B =
    val cache = mutable.Map.empty[A, B]
    (a: A) =>
      cache.getOrElseUpdate(a, f(a))
  
  /** TTL付きキャッシュデコレータ */
  def withTTLCache[A, B](f: A => B, ttlMs: Long): A => B =
    val cache = mutable.Map.empty[A, (B, Long)]
    (a: A) =>
      val now = System.currentTimeMillis()
      cache.get(a) match
        case Some((value, timestamp)) if now - timestamp < ttlMs => value
        case _ =>
          val result = f(a)
          cache(a) = (result, now)
          result
  
  // ----------------------------------------
  // バリデーションデコレータ
  // ----------------------------------------
  
  /** 入力バリデーションを追加するデコレータ */
  def withValidation[A, B](f: A => B)(validator: A => Boolean, errorMsg: String): A => B =
    (a: A) =>
      if validator(a) then f(a)
      else throw new IllegalArgumentException(s"$errorMsg: $a")
  
  /** 出力バリデーションを追加するデコレータ */
  def withPostCondition[A, B](f: A => B)(validator: B => Boolean, errorMsg: String): A => B =
    (a: A) =>
      val result = f(a)
      if validator(result) then result
      else throw new IllegalStateException(s"$errorMsg: $result")
  
  // ----------------------------------------
  // エラーハンドリングデコレータ
  // ----------------------------------------
  
  /** 例外をOptionに変換するデコレータ */
  def withOptionResult[A, B](f: A => B): A => Option[B] =
    (a: A) => Try(f(a)).toOption
  
  /** 例外をEitherに変換するデコレータ */
  def withEitherResult[A, B](f: A => B): A => Either[Throwable, B] =
    (a: A) => Try(f(a)).toEither
  
  /** デフォルト値を返すデコレータ */
  def withDefault[A, B](f: A => B, default: B): A => B =
    (a: A) => Try(f(a)).getOrElse(default)
  
  // ----------------------------------------
  // 非同期デコレータ
  // ----------------------------------------
  
  import scala.concurrent.{Future, ExecutionContext}
  
  /** 関数を非同期化するデコレータ */
  def withAsync[A, B](f: A => B)(implicit ec: ExecutionContext): A => Future[B] =
    (a: A) => Future(f(a))
  
  // ----------------------------------------
  // レート制限デコレータ
  // ----------------------------------------
  
  /** レート制限を追加するデコレータ */
  def withRateLimit[A, B](f: A => B, minIntervalMs: Long): A => B =
    var lastCall = 0L
    (a: A) =>
      val now = System.currentTimeMillis()
      val elapsed = now - lastCall
      if elapsed < minIntervalMs then
        Thread.sleep(minIntervalMs - elapsed)
      lastCall = System.currentTimeMillis()
      f(a)

// ============================================
// 3. ヘルパー型（ログとメトリクス収集）
// ============================================

/** ログ収集器 */
class LogCollector:
  private val logs = mutable.ListBuffer.empty[String]
  
  def add(message: String): Unit = logs += message
  def getAll: List[String] = logs.toList
  def clear(): Unit = logs.clear()
  def last: Option[String] = logs.lastOption

/** メトリクス収集器 */
class MetricsCollector:
  private val metrics = mutable.Map.empty[String, mutable.ListBuffer[Long]]
  
  def record(name: String, value: Long): Unit =
    metrics.getOrElseUpdate(name, mutable.ListBuffer.empty) += value
  
  def get(name: String): List[Long] = metrics.get(name).map(_.toList).getOrElse(Nil)
  def average(name: String): Option[Double] =
    val values = get(name)
    if values.isEmpty then None else Some(values.sum.toDouble / values.length)
  def clear(): Unit = metrics.clear()

// ============================================
// 4. デコレータの合成
// ============================================

object DecoratorComposition:
  
  /** デコレータを合成する */
  def compose[A, B](f: A => B, decorators: List[(A => B) => (A => B)]): A => B =
    decorators.foldLeft(f) { (decorated, decorator) =>
      decorator(decorated)
    }
  
  /** デコレータをパイプラインで適用 */
  extension [A, B](f: A => B)
    def |>[C](decorator: (A => B) => (A => C)): A => C = decorator(f)

// ============================================
// 5. ストリームデコレータ
// ============================================

object StreamDecorators:
  
  /** ストリームにフィルタを追加 */
  def withFilter[A](predicate: A => Boolean): LazyList[A] => LazyList[A] =
    stream => stream.filter(predicate)
  
  /** ストリームにマップを追加 */
  def withMap[A, B](f: A => B): LazyList[A] => LazyList[B] =
    stream => stream.map(f)
  
  /** ストリームにテイクを追加 */
  def withTake[A](n: Int): LazyList[A] => LazyList[A] =
    stream => stream.take(n)
  
  /** ストリームにログを追加 */
  def withStreamLogging[A](name: String)(implicit log: LogCollector): LazyList[A] => LazyList[A] =
    stream => stream.map { a =>
      log.add(s"[$name] processing: $a")
      a
    }

// ============================================
// 6. コレクションデコレータ
// ============================================

/** 監査機能付きリスト */
case class AuditedList[A](
  items: List[A],
  operations: List[String] = Nil
):
  def add(item: A): AuditedList[A] =
    copy(
      items = items :+ item,
      operations = operations :+ s"add($item)"
    )
  
  def remove(item: A): AuditedList[A] =
    copy(
      items = items.filterNot(_ == item),
      operations = operations :+ s"remove($item)"
    )
  
  def map[B](f: A => B): AuditedList[B] =
    AuditedList(
      items.map(f),
      operations :+ "map"
    )
  
  def filter(p: A => Boolean): AuditedList[A] =
    copy(
      items = items.filter(p),
      operations :+ "filter"
    )
  
  def size: Int = items.size
  def toList: List[A] = items

object AuditedList:
  def empty[A]: AuditedList[A] = AuditedList(Nil)
  def apply[A](items: A*): AuditedList[A] = AuditedList(items.toList)

// ============================================
// 7. HTTPリクエストデコレータ（シミュレーション）
// ============================================

/** HTTPレスポンス */
case class HttpResponse(status: Int, body: String, headers: Map[String, String] = Map.empty)

/** HTTPクライアントのシミュレーション */
trait HttpClient:
  def get(url: String): HttpResponse

/** 基本HTTPクライアント */
class SimpleHttpClient extends HttpClient:
  def get(url: String): HttpResponse =
    // シミュレーション
    HttpResponse(200, s"Response from $url")

/** ログ付きHTTPクライアント */
class LoggingHttpClient(client: HttpClient)(implicit log: LogCollector) extends HttpClient:
  def get(url: String): HttpResponse =
    log.add(s"[HTTP] GET $url")
    val response = client.get(url)
    log.add(s"[HTTP] Response: ${response.status}")
    response

/** リトライ付きHTTPクライアント */
class RetryingHttpClient(client: HttpClient, maxRetries: Int) extends HttpClient:
  def get(url: String): HttpResponse =
    def attempt(remaining: Int): HttpResponse =
      Try(client.get(url)) match
        case Success(response) if response.status < 500 => response
        case Success(response) if remaining > 0 => attempt(remaining - 1)
        case Success(response) => response
        case Failure(e) if remaining > 0 => attempt(remaining - 1)
        case Failure(e) => throw e
    attempt(maxRetries)

/** キャッシュ付きHTTPクライアント */
class CachingHttpClient(client: HttpClient) extends HttpClient:
  private val cache = mutable.Map.empty[String, HttpResponse]
  
  def get(url: String): HttpResponse =
    cache.getOrElseUpdate(url, client.get(url))
  
  def clearCache(): Unit = cache.clear()

// ============================================
// 8. ビルダースタイルのデコレータ
// ============================================

/** 関数ビルダー */
class FunctionBuilder[A, B](f: A => B):
  private var current: A => B = f
  
  def withLogging(name: String)(implicit log: LogCollector): FunctionBuilder[A, B] =
    current = FunctionDecorators.withLogging(current, name)
    this
  
  def withCache(): FunctionBuilder[A, B] =
    current = FunctionDecorators.withCache(current)
    this
  
  def withValidation(validator: A => Boolean, errorMsg: String): FunctionBuilder[A, B] =
    current = FunctionDecorators.withValidation(current)(validator, errorMsg)
    this
  
  def withDefault(default: B): FunctionBuilder[A, B] =
    current = FunctionDecorators.withDefault(current, default)
    this
  
  def build: A => B = current

object FunctionBuilder:
  def apply[A, B](f: A => B): FunctionBuilder[A, B] = new FunctionBuilder(f)
