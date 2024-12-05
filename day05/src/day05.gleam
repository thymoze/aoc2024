import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
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

fn to_int(string: String) -> Int {
  let assert Ok(val) = int.parse(string)
  val
}

type Rules =
  dict.Dict(Int, set.Set(Int))

type Updates =
  List(List(Int))

fn parse(input: String) -> #(Rules, Updates) {
  let assert Ok(#(rules, updates)) = string.split_once(input, "\n\n")

  let rules =
    string.split(rules, "\n")
    |> list.map(fn(rule) {
      let assert Ok(#(x, y)) = string.split_once(rule, "|")
      let x = to_int(x)
      let y = to_int(y)
      #(y, x)
    })
    |> list.group(by: fn(pair) { pair.0 })
    |> dict.map_values(fn(_, values) {
      list.map(values, pair.second) |> set.from_list
    })

  let updates =
    string.split(updates, "\n")
    |> list.map(fn(update) { string.split(update, ",") |> list.map(to_int) })

  #(rules, updates)
}

fn sum_middle(updates: Updates) -> Int {
  list.map(updates, fn(pages) {
    let assert Ok(middle) =
      list.drop(pages, list.length(pages) / 2) |> list.first
    middle
  })
  |> int.sum
}

fn page_ordering(rules: Rules) -> fn(Int, Int) -> order.Order {
  fn(a, b) {
    case dict.get(rules, a) {
      Ok(before) -> {
        case set.contains(before, b) {
          True -> order.Gt
          False -> order.Lt
        }
      }
      Error(_) -> order.Eq
    }
  }
}

fn is_sorted_asc(
  list: List(Int),
  by compare: fn(Int, Int) -> order.Order,
) -> Bool {
  case list {
    [] | [_] -> True
    [x, y, ..rest] -> {
      case compare(x, y) {
        order.Lt | order.Eq -> is_sorted_asc([y, ..rest], compare)
        order.Gt -> False
      }
    }
  }
}

fn part1(rules: Rules, updates: Updates) -> Int {
  list.filter(updates, fn(pages) {
    is_sorted_asc(pages, by: page_ordering(rules))
  })
  |> sum_middle
}

fn part2(rules: Rules, updates: Updates) -> Int {
  list.filter(updates, fn(pages) {
    !is_sorted_asc(pages, by: page_ordering(rules))
  })
  |> list.map(fn(pages) { list.sort(pages, by: page_ordering(rules)) })
  |> sum_middle
}

pub fn main() {
  let #(rules, updates) =
    read("./input.txt")
    |> parse

  part1(rules, updates) |> io.debug
  part2(rules, updates) |> io.debug
}
