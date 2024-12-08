import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
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

fn in_bounds(width: Int, height: Int) -> fn(#(Int, Int)) -> Bool {
  fn(loc) {
    let #(y, x) = loc
    { y >= 0 && y < height } && { x >= 0 && x < width }
  }
}

fn calc_antinodes(
  width: Int,
  height: Int,
  locations: List(#(Int, Int)),
) -> set.Set(#(Int, Int)) {
  list.combination_pairs(locations)
  |> list.flat_map(fn(location_pair) {
    let #(#(ay, ax), #(by, bx)) = location_pair
    let #(diffy, diffx) = #(by - ay, bx - ax)

    [#(ay - diffy, ax - diffx), #(by + diffy, bx + diffx)]
  })
  |> set.from_list
  |> set.filter(in_bounds(width, height))
}

fn calc_antinodes2(
  width: Int,
  height: Int,
  locations: List(#(Int, Int)),
) -> set.Set(#(Int, Int)) {
  list.combination_pairs(locations)
  |> list.flat_map(fn(location_pair) {
    let #(a, b) = location_pair
    let #(diffy, diffx) = #(b.0 - a.0, b.1 - a.1)

    let max_steps =
      int.max(
        height / int.absolute_value(diffy),
        width / int.absolute_value(diffx),
      )

    let collect = fn(loc, diff) {
      let #(locy, locx) = loc
      let #(diffy, diffx) = diff
      list.range(0, max_steps)
      |> list.fold_until([], fn(acc, i) {
        let antinode = #(locy + { i * diffy }, locx + { i * diffx })
        case in_bounds(width, height)(antinode) {
          True -> list.Continue([antinode, ..acc])
          False -> list.Stop(acc)
        }
      })
    }

    list.append(collect(a, #(-diffy, -diffx)), collect(b, #(diffy, diffx)))
  })
  |> set.from_list
  |> set.filter(in_bounds(width, height))
}

pub fn main() {
  let lines = read_lines("./input.txt")
  let height = list.length(lines)
  let width = list.first(lines) |> result.map(string.length) |> result.unwrap(0)

  let input =
    list.index_map(lines, fn(line, i) {
      string.to_graphemes(line)
      |> list.index_map(fn(c, j) { #(c, #(i, j)) })
      |> list.filter(fn(x) { x.0 != "." })
    })
    |> list.flatten
    |> list.group(fn(x) { x.0 })
    |> dict.map_values(fn(_, v) { list.map(v, pair.second) })

  dict.fold(input, set.new(), fn(antinodes, _, locations) {
    set.union(antinodes, calc_antinodes(width, height, locations))
  })
  |> set.size
  |> io.debug

  dict.fold(input, set.new(), fn(antinodes, _, locations) {
    set.union(antinodes, calc_antinodes2(width, height, locations))
  })
  |> set.size
  |> io.debug
}
