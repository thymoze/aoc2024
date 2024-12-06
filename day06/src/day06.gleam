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

type Position =
  #(Int, Int)

type Direction {
  Up
  Down
  Right
  Left
}

type Guard {
  Guard(position: Position, direction: Direction)
}

type Obstructions =
  set.Set(Position)

fn next_position(pos: Position, dir: Direction) -> Position {
  case dir {
    Up -> #(pos.0 - 1, pos.1)
    Down -> #(pos.0 + 1, pos.1)
    Right -> #(pos.0, pos.1 + 1)
    Left -> #(pos.0, pos.1 - 1)
  }
}

fn next_direction(dir: Direction) -> Direction {
  case dir {
    Up -> Right
    Down -> Left
    Right -> Down
    Left -> Up
  }
}

fn is_out_of_bounds(width: Int, height: Int, pos: Position) -> Bool {
  { pos.0 < 0 || pos.0 >= height } || { pos.1 < 0 || pos.1 >= width }
}

fn step(
  width: Int,
  height: Int,
  obstructions: Obstructions,
  guard: Guard,
) -> option.Option(Guard) {
  let Guard(pos, dir) = guard

  use <- bool.guard({ is_out_of_bounds(width, height, pos) }, None)

  let next_pos = next_position(pos, dir)

  case set.contains(obstructions, next_pos) {
    True -> Some(Guard(pos, next_direction(dir)))
    False -> Some(Guard(next_pos, dir))
  }
}

fn part1(
  width: Int,
  height: Int,
  obstructions: Obstructions,
  guard: Guard,
  visited: set.Set(#(Int, Int)),
) -> set.Set(#(Int, Int)) {
  case step(width, height, obstructions, guard) {
    Some(next_guard) ->
      part1(
        width,
        height,
        obstructions,
        next_guard,
        set.insert(visited, guard.position),
      )
    None -> visited
  }
}

fn is_loop(
  width: Int,
  height: Int,
  obstructions: Obstructions,
  guard: Guard,
  visited: set.Set(Guard),
) -> Bool {
  case step(width, height, obstructions, guard) {
    Some(next_guard) -> {
      set.contains(visited, next_guard)
      || is_loop(
        width,
        height,
        obstructions,
        next_guard,
        set.insert(visited, guard),
      )
    }
    None -> False
  }
}

fn part2_walk(
  width: Int,
  height: Int,
  obstructions: Obstructions,
  original_guard_pos: Position,
  guard: Guard,
  path: set.Set(Position),
  loops: set.Set(Position),
) -> Int {
  let Guard(pos, dir) = guard
  let new_obstruction = next_position(pos, dir)

  let loop_found =
    !set.contains(path, new_obstruction)
    && new_obstruction != original_guard_pos
    && is_loop(
      width,
      height,
      set.insert(obstructions, new_obstruction),
      guard,
      set.new(),
    )

  let loops = case loop_found {
    True -> {
      set.insert(loops, new_obstruction)
    }
    False -> loops
  }

  case step(width, height, obstructions, guard) {
    Some(next_guard) -> {
      part2_walk(
        width,
        height,
        obstructions,
        original_guard_pos,
        next_guard,
        set.insert(path, guard.position),
        loops,
      )
    }

    None -> set.size(loops)
  }
}

fn part2(width: Int, height: Int, obstructions: Obstructions, guard: Guard) {
  part2_walk(
    width,
    height,
    obstructions,
    guard.position,
    guard,
    set.new(),
    set.new(),
  )
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
            "^" -> #(Some(Guard(#(i, j), Up)), acc.1)
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
  part2(width, height, obstructions, guard) |> io.debug
}
