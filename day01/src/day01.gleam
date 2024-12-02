import gleam/dict
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

pub fn main() {
  let lines = read_lines("./input.txt")

  let #(l, r) =
    lines
    |> list.map(fn(line) {
      let assert Ok(#(l, r)) = string.trim(line) |> string.split_once("   ")
      let assert Ok(l) = int.base_parse(l, 10)
      let assert Ok(r) = int.base_parse(r, 10)
      #(l, r)
    })
    |> list.unzip

  let l = list.sort(l, by: int.compare)
  let r = list.sort(r, by: int.compare)

  let sum = list.map2(l, r, fn(x, y) { int.absolute_value(x - y) }) |> int.sum
  io.debug(sum)

  let counts =
    list.group(r, fn(x) { x }) |> dict.map_values(fn(_, v) { list.length(v) })

  let similarity =
    l
    |> list.map(fn(x) { x * { counts |> dict.get(x) |> result.unwrap(0) } })
    |> int.sum
  io.debug(similarity)
}
