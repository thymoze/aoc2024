import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import simplifile

fn read_file(from: String) -> List(String) {
  let assert Ok(lines) =
    simplifile.read(from)
    |> result.map(fn(lines) { lines |> string.trim |> string.split("\n") })
  lines
}

fn to_int(string: String) -> Int {
  let assert Ok(val) = int.parse(string)
  val
}

type Position {
  Position(x: Int, y: Int)
}

type Trail {
  Trail(pos: Position, height: Int)
}

type Map =
  dict.Dict(Trail, set.Set(Trail))

fn add_path(map: Map, between one: Trail, and other: Trail) -> Map {
  use existing <- dict.upsert(map, one)
  option.unwrap(existing, set.new()) |> set.insert(other)
}

fn parse(input: List(List(Int))) -> Map {
  let ysize = list.length(input)
  let xsize = list.first(input) |> result.map(list.length) |> result.unwrap(0)

  use acc, line, y <- list.index_fold(input, dict.new())
  use acc, height, x <- list.index_fold(line, acc)

  let self = Trail(Position(x, y), height)

  let add_left = fn(map: Map) {
    use <- bool.guard(x < 1, map)
    {
      use h <- result.try(list.drop(line, x - 1) |> list.first)
      use <- bool.guard(h - height != 1, Error(Nil))
      let left = Trail(Position(x - 1, y), h)
      Ok(add_path(map, between: self, and: left))
    }
    |> result.unwrap(map)
  }
  let add_right = fn(map: Map) {
    use <- bool.guard(x >= xsize - 1, map)
    {
      use h <- result.try(list.drop(line, x + 1) |> list.first)
      use <- bool.guard(h - height != 1, Error(Nil))
      let right = Trail(Position(x + 1, y), h)
      Ok(add_path(map, between: self, and: right))
    }
    |> result.unwrap(map)
  }
  let add_up = fn(map: Map) {
    use <- bool.guard(y < 1, map)
    {
      use line <- result.try(list.drop(input, y - 1) |> list.first)
      use h <- result.try(list.drop(line, x) |> list.first)
      use <- bool.guard(h - height != 1, Error(Nil))
      let up = Trail(Position(x, y - 1), h)
      Ok(add_path(map, between: self, and: up))
    }
    |> result.unwrap(map)
  }
  let add_down = fn(map: Map) {
    use <- bool.guard(y >= ysize - 1, map)
    {
      use line <- result.try(list.drop(input, y + 1) |> list.first)
      use h <- result.try(list.drop(line, x) |> list.first)
      use <- bool.guard(h - height != 1, Error(Nil))
      let down = Trail(Position(x, y + 1), h)
      Ok(add_path(map, between: self, and: down))
    }
    |> result.unwrap(map)
  }

  acc |> add_left |> add_right |> add_up |> add_down
}

fn hike_loop(
  map: Map,
  next: Trail,
  path: List(Trail),
  visited: set.Set(Trail),
) -> set.Set(List(Trail)) {
  case dict.get(map, next) {
    Ok(paths) -> {
      let paths = set.difference(paths, visited)

      use acc, trail <- set.fold(paths, set.new())
      case trail {
        Trail(_, height: 9) -> set.insert(acc, [trail, next, ..path])
        _ ->
          set.union(
            acc,
            hike_loop(map, trail, [next, ..path], set.insert(visited, next)),
          )
      }
    }
    Error(Nil) -> set.new()
  }
}

fn hike(map: Map, trailhead: Trail) -> set.Set(List(Trail)) {
  hike_loop(map, trailhead, [], set.new())
}

pub fn main() {
  let map =
    read_file("./input.txt")
    |> list.map(fn(line) { string.to_graphemes(line) |> list.map(to_int) })
    |> parse

  let paths =
    dict.filter(map, fn(trail, _) { trail.height == 0 })
    |> dict.keys
    |> list.map(fn(head) { hike(map, head) })

  list.map(paths, set.map(_, list.first))
  |> list.map(set.size)
  |> int.sum
  |> io.debug

  list.map(paths, set.size)
  |> int.sum
  |> io.debug

  Nil
}
