import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn read_lines(from: String) -> List(String) {
  let assert Ok(lines) =
    simplifile.read(from)
    |> result.map(fn(lines) { lines |> string.trim |> string.split("\n") })
  lines
}

fn to_int(string: String) -> Int {
  let assert Ok(val) = int.parse(string)
  val
}

fn is_safe(levels: List(Int)) -> Bool {
  let diffs =
    levels
    |> list.window_by_2
    |> list.map(fn(x) { x.0 - x.1 })

  let assert Ok(dir) = diffs |> list.first |> result.map(int.compare(_, 0))

  diffs
  |> list.all(fn(x) {
    let comp = int.compare(x, 0)
    let abs = int.absolute_value(x)
    dir == comp && 1 <= abs && abs <= 3
  })
}

fn is_safe_dampened(levels: List(Int)) -> Bool {
  is_safe(levels)
  || list.combinations(levels, list.length(levels) - 1)
  |> list.any(is_safe)
}

pub fn main() {
  let levels =
    read_lines("./input.txt")
    |> list.map(string.split(_, " "))
    |> list.map(list.map(_, to_int))

  let safe = levels |> list.count(is_safe)
  io.debug(safe)

  let safe_dampened = levels |> list.count(is_safe_dampened)
  io.debug(safe_dampened)
}
