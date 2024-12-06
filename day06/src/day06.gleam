import gleam/bool
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import simplifile

fn read_lines(from: String) -> List(String) {
  let assert Ok(lines) =
    simplifile.read(from)
    |> result.map(fn(lines) { lines |> string.trim |> string.split("\n") })
  lines
}

type Guard =
  #(#(Int, Int), String)

type Obstructions =
  set.Set(#(Int, Int))

fn part1(
  width: Int,
  height: Int,
  obstructions: Obstructions,
  guard: Guard,
  visited: set.Set(#(Int, Int)),
) -> set.Set(#(Int, Int)) {
  let #(location, direction) = guard
  use <- bool.guard(
    { location.0 < 0 || location.0 >= height }
      || { location.1 < 0 || location.1 >= width },
    visited,
  )

  let step = fn(loc: #(Int, Int), dir: String) {
    case dir {
      "^" -> #(loc.0 - 1, loc.1)
      ">" -> #(loc.0, loc.1 + 1)
      "<" -> #(loc.0, loc.1 - 1)
      "v" -> #(loc.0 + 1, loc.1)
      _ -> panic
    }
  }

  let next_location = step(location, direction)

  let next_guard = case set.contains(obstructions, next_location) {
    True ->
      case direction {
        "^" -> #(location, ">")
        ">" -> #(location, "v")
        "<" -> #(location, "^")
        "v" -> #(location, "<")
        _ -> panic
      }
    False -> #(next_location, direction)
  }

  part1(width, height, obstructions, next_guard, set.insert(visited, location))
}

pub fn main() {
  let input = read_lines("./input.txt")

  let height = list.length(input)
  let width = list.first(input) |> result.map(string.length) |> result.unwrap(0)

  let assert #(Some(guard), obstructions) =
    list.index_fold(input, #(None, set.new()), fn(map, line, i) {
      let #(guard, obstructions) = map

      let #(line_guard, line_obstructions) =
        string.to_graphemes(line)
        |> list.index_fold(#(None, set.new()), fn(acc, c, j) {
          case c {
            "#" -> #(acc.0, set.insert(acc.1, #(i, j)))
            "^" | ">" | "<" | "v" -> #(Some(#(#(i, j), c)), acc.1)
            _ -> acc
          }
        })

      let obstructions = set.union(obstructions, line_obstructions)

      case line_guard {
        Some(_) -> #(line_guard, obstructions)
        None -> #(guard, obstructions)
      }
    })

  part1(width, height, obstructions, guard, set.new()) |> set.size |> io.debug
}
