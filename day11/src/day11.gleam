import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn read_file(from: String) -> String {
  let assert Ok(lines) =
    simplifile.read(from)
    |> result.map(fn(lines) { lines |> string.trim })
  lines
}

fn to_int(string: String) -> Int {
  let assert Ok(val) = int.parse(string)
  val
}

type Cache =
  Dict(#(Int, Int), Int)

fn blink(stone: Int, epoch: Int, stop: Int, cache: Cache) -> #(Int, Cache) {
  use <- bool.guard(epoch == stop, #(1, cache))

  use <- bool.lazy_guard(dict.has_key(cache, #(stone, epoch)), fn() {
    let assert Ok(cached) = dict.get(cache, #(stone, epoch))
    #(cached, cache)
  })

  case stone {
    0 -> {
      let #(stones, cache) = blink(1, epoch + 1, stop, cache)
      let cache: Cache = dict.insert(cache, #(stone, epoch), stones)
      #(stones, cache)
    }
    _ -> {
      let assert Ok(digits) = int.digits(stone, 10)
      case list.length(digits) % 2 == 0 {
        True -> {
          let assert Ok(left) =
            list.take(digits, list.length(digits) / 2) |> int.undigits(10)
          let assert Ok(right) =
            list.drop(digits, list.length(digits) / 2) |> int.undigits(10)

          let #(lstones, cache) = blink(left, epoch + 1, stop, cache)
          let #(rstones, cache) = blink(right, epoch + 1, stop, cache)
          let stones = lstones + rstones
          let cache = dict.insert(cache, #(stone, epoch), stones)
          #(stones, cache)
        }
        False -> {
          let #(stones, cache) = blink(stone * 2024, epoch + 1, stop, cache)
          let cache = dict.insert(cache, #(stone, epoch), stones)
          #(stones, cache)
        }
      }
    }
  }
}

pub fn main() {
  let stones = read_file("./input.txt") |> string.split(" ") |> list.map(to_int)

  list.map(stones, fn(stone) { blink(stone, 0, 25, dict.new()).0 })
  |> int.sum
  |> io.debug

  list.map(stones, fn(stone) { blink(stone, 0, 75, dict.new()).0 })
  |> int.sum
  |> io.debug
}
