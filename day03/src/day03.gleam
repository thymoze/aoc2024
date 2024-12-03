import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
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

fn part1(input: String) -> Int {
  let assert Ok(re) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")
  let matches = regexp.scan(with: re, content: input)

  list.map(matches, fn(match) {
    list.map(match.submatches, fn(x) {
      let assert Some(x) = x
      to_int(x)
    })
    |> int.product
  })
  |> int.sum
}

fn part2(input: String) -> Int {
  let assert Ok(re) = regexp.from_string("(.*?)mul\\((\\d+),(\\d+)\\)")
  let matches = regexp.scan(with: re, content: input)

  list.fold(matches, #(True, 0), fn(acc, match) {
    let instruction = case list.first(match.submatches) {
      Ok(Some(i)) -> i
      _ -> ""
    }
    use <- bool.guard(string.contains(does: instruction, contain: "don't()"), #(
      False,
      acc.1,
    ))

    case acc.0 || string.contains(does: instruction, contain: "do()") {
      True -> {
        let res =
          list.drop(match.submatches, 1)
          |> list.map(fn(x) {
            let assert Some(x) = x
            to_int(x)
          })
          |> int.product
        #(True, acc.1 + res)
      }
      False -> acc
    }
  }).1
}

pub fn main() {
  let input = read("./input.txt")

  io.debug(part1(input))
  io.debug(part2(input))
}
