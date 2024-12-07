import gleam/int
import gleam/io
import gleam/list
import gleam/pair
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

fn part1(result: Int, operands: List(Int)) -> Bool {
  case operands {
    [] -> panic
    [x] -> x == result
    [x, y, ..rest] -> {
      {
        let sum = x + y
        sum <= result && part1(result, [sum, ..rest])
      }
      || {
        let prod = x * y
        prod <= result && part1(result, [prod, ..rest])
      }
    }
  }
}

fn part2(result: Int, operands: List(Int)) -> Bool {
  case operands {
    [] -> panic
    [x] -> x == result
    [x, y, ..rest] -> {
      {
        let sum = x + y
        sum <= result && part2(result, [sum, ..rest])
      }
      || {
        let prod = x * y
        prod <= result && part2(result, [prod, ..rest])
      }
      || {
        let assert Ok(y_digits) = int.digits(y, 10)
        let concat = x * { list.fold(y_digits, 1, fn(acc, _) { acc * 10 }) } + y
        concat <= result && part2(result, [concat, ..rest])
      }
    }
  }
}

pub fn main() {
  let input =
    read_lines("./input.txt")
    |> list.map(fn(line) {
      let assert Ok(#(result, operands)) = string.split_once(line, ": ")
      let operands = string.split(operands, " ") |> list.map(to_int)
      #(to_int(result), operands)
    })

  list.filter(input, fn(eq) { part1(eq.0, eq.1) })
  |> list.map(pair.first)
  |> int.sum
  |> io.debug

  list.filter(input, fn(eq) { part2(eq.0, eq.1) })
  |> list.map(pair.first)
  |> int.sum
  |> io.debug
}
