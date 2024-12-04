import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/result
import gleam/set
import gleam/string
import simplifile

fn read(from: String) -> String {
  let assert Ok(lines) =
    simplifile.read(from)
    |> result.map(fn(lines) { lines |> string.trim })
  lines
}

fn combine(lists: List(String), line: String, offset: Int) -> List(String) {
  let graphemes = string.to_graphemes(line)
  case lists {
    [] -> graphemes
    l -> {
      let abs_offset = int.absolute_value(offset)
      case offset {
        0 -> {
          list.map2(l, graphemes, fn(x, y) { x <> y })
        }
        _ if offset > 0 -> {
          let #(front, middle) =
            list.split(
              graphemes,
              list.length(graphemes) + abs_offset - list.length(l),
            )

          list.append(front, list.map2(l, middle, fn(x, y) { x <> y }))
          |> list.append(list.drop(l, list.length(l) - abs_offset))
        }
        _ -> {
          let #(front, middle) = list.split(l, abs_offset)

          list.append(front, list.map2(middle, graphemes, fn(x, y) { x <> y }))
          |> list.append(list.drop(graphemes, list.length(l) - abs_offset))
        }
      }
    }
  }
}

fn part1(input: String) -> Int {
  let horizontal = string.split(input, "\n")
  let vertical =
    list.fold(horizontal, [], fn(acc, line) { combine(acc, line, 0) })
  let rdiagonal =
    list.fold(horizontal, #([], 0), fn(acc, line) {
      #(combine(acc.0, line, acc.1), acc.1 + 1)
    }).0
  let ldiagonal =
    list.fold(horizontal, #([], 0), fn(acc, line) {
      #(combine(acc.0, line, acc.1), acc.1 - 1)
    }).0

  let count = fn(l: List(String)) -> Int {
    let assert Ok(re) = regexp.from_string("(?=XMAS|SAMX)")

    list.map(l, fn(x) {
      let matches = regexp.scan(with: re, content: x)
      list.length(matches)
    })
    |> int.sum
  }

  count(horizontal) + count(vertical) + count(rdiagonal) + count(ldiagonal)
}

fn part2(input: String) -> Int {
  let horizontal = string.split(input, "\n")
  let width =
    {
      list.first(horizontal)
      |> result.map(string.length)
      |> result.unwrap(0)
    }
    - 1
  let height = list.length(horizontal) - 1

  let rdiagonal =
    list.fold(horizontal, #([], 0), fn(acc, line) {
      #(combine(acc.0, line, acc.1), acc.1 + 1)
    }).0
  let ldiagonal =
    list.fold(horizontal, #([], 0), fn(acc, line) {
      #(combine(acc.0, line, acc.1), acc.1 - 1)
    }).0

  let rdia =
    list.index_map(rdiagonal, fn(line, i) {
      string.to_graphemes(line)
      |> list.window(3)
      |> list.index_map(fn(x, j) { #(j + 1, x) })
      |> list.filter(fn(x) { x.1 == ["M", "A", "S"] || x.1 == ["S", "A", "M"] })
      |> list.map(fn(x) {
        case i {
          _ if i <= height -> #(height - i + x.0, x.0)
          _ -> #(x.0, x.0 + { i - height })
        }
      })
    })
    |> list.filter(fn(l) { !list.is_empty(l) })
    |> list.flatten
    |> set.from_list

  let ldia =
    list.index_map(ldiagonal, fn(line, i) {
      string.to_graphemes(line)
      |> list.window(3)
      |> list.index_map(fn(x, j) { #(j + 1, x) })
      |> list.filter(fn(x) { x.1 == ["M", "A", "S"] || x.1 == ["S", "A", "M"] })
      |> list.map(fn(x) {
        case i {
          _ if i <= width -> #(x.0, i - x.0)
          _ -> #(x.0 + { i - height }, width - x.0)
        }
      })
    })
    |> list.filter(fn(l) { !list.is_empty(l) })
    |> list.flatten
    |> set.from_list

  set.intersection(rdia, ldia) |> set.size
}

pub fn main() {
  let input = read("./input.txt")

  part1(input) |> io.debug
  part2(input) |> io.debug
}
