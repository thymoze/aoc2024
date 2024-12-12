import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
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

type Pos {
  Pos(x: Int, y: Int)
}

type Region {
  Region(kind: String, pos: Pos)
}

type Garden =
  Dict(Pos, Region)

type Result {
  Result(area: Int, perimeter: List(Fence))
}

type Dir {
  Up
  Down
  Left
  Right
}

type Fence {
  Fence(dir: Dir, pos: Pos)
}

fn neighbors(garden: Garden, region: Region) -> List(Region) {
  let Pos(x, y) = region.pos
  [
    dict.get(garden, Pos(x - 1, y)),
    dict.get(garden, Pos(x + 1, y)),
    dict.get(garden, Pos(x, y - 1)),
    dict.get(garden, Pos(x, y + 1)),
  ]
  |> result.values
  |> list.filter(fn(r) { r.kind == region.kind })
}

fn dfs(
  garden: Garden,
  region: Region,
  visited: set.Set(Region),
) -> #(Result, set.Set(Region)) {
  let neighs = neighbors(garden, region)

  let #(result, visited) =
    list.fold(
      neighs,
      #(Result(0, []), set.insert(visited, region)),
      fn(acc, neighbor) {
        let #(current, visited) = acc
        use <- bool.guard(set.contains(visited, neighbor), acc)

        let #(result, neighbor_visited) = dfs(garden, neighbor, visited)
        let visited = set.union(visited, neighbor_visited)

        let next =
          Result(
            current.area + result.area,
            list.append(current.perimeter, result.perimeter),
          )
        #(next, visited)
      },
    )

  let Pos(x, y) = region.pos
  let perimeter =
    [
      list.find(neighs, fn(n) { n.pos.y == y - 1 })
        |> result.replace_error(Fence(Up, region.pos)),
      list.find(neighs, fn(n) { n.pos.y == y + 1 })
        |> result.replace_error(Fence(Down, region.pos)),
      list.find(neighs, fn(n) { n.pos.x == x - 1 })
        |> result.replace_error(Fence(Left, region.pos)),
      list.find(neighs, fn(n) { n.pos.x == x + 1 })
        |> result.replace_error(Fence(Right, region.pos)),
    ]
    |> list.filter_map(fn(r) {
      case r {
        Ok(_) -> Error(Nil)
        Error(f) -> Ok(f)
      }
    })

  #(Result(result.area + 1, list.append(result.perimeter, perimeter)), visited)
}

fn segments(list: List(Int)) -> Int {
  case list {
    [] -> 0
    [_] -> 1
    [a, b, ..rest] ->
      case int.absolute_value(a - b) {
        1 -> segments([b, ..rest])
        _ -> 1 + segments([b, ..rest])
      }
  }
}

fn price(garden: Garden, bulk_discount: Bool) -> Int {
  dict.fold(garden, #(0, set.new()), fn(acc, _, region) {
    let #(price, visited) = acc
    use <- bool.guard(set.contains(visited, region), acc)

    let #(result, vis) = dfs(garden, region, set.new())
    let visited = set.union(visited, vis)

    let region_price = case bulk_discount {
      False -> result.area * list.length(result.perimeter)
      True -> {
        let fences =
          list.group(result.perimeter, fn(r) {
            case r.dir {
              Up | Down -> #(r.dir, r.pos.y)
              Left | Right -> #(r.dir, r.pos.x)
            }
          })
          |> dict.fold(0, fn(acc, k, fences) {
            let fences =
              case k.0 {
                Up | Down -> list.map(fences, fn(f) { f.pos.x })
                Left | Right -> list.map(fences, fn(f) { f.pos.y })
              }
              |> list.sort(by: int.compare)

            acc + segments(fences)
          })

        result.area * fences
      }
    }

    #(price + region_price, visited)
  }).0
}

pub fn main() {
  let garden =
    read_file("./input.txt")
    |> list.index_map(fn(line, y) {
      string.to_graphemes(line)
      |> list.index_map(fn(region, x) {
        #(Pos(x, y), Region(region, Pos(x, y)))
      })
    })
    |> list.flatten
    |> dict.from_list

  price(garden, False) |> io.debug
  price(garden, True) |> io.debug

  Nil
}
