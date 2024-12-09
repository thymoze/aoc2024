import gleam/bool
import gleam/deque
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import simplifile

fn read_file(from: String) -> String {
  let assert Ok(lines) =
    simplifile.read(from)
    |> result.map(fn(lines) { lines |> string.trim })
  lines
}

fn to_int(string: String) -> Int {
  let assert Ok(val) = int.parse(string)
  val
}

type File {
  File(id: Int, size: Int)
}

type Side {
  Start
  End
}

fn part1_rec(
  files: deque.Deque(File),
  frees: List(Int),
  side: Side,
  index: Int,
  checksum: Int,
) -> Int {
  case side {
    Start -> {
      case deque.pop_front(files) {
        Ok(#(file, rest)) -> {
          let res = file.id * sum(from: index, to: index + file.size)

          part1_rec(rest, frees, End, index + file.size, res + checksum)
        }
        _ -> checksum
      }
    }
    End -> {
      case deque.pop_back(files), frees {
        Ok(#(file, rest)), [free, ..frees] ->
          case int.compare(file.size, free) {
            order.Eq -> {
              let res = file.id * sum(from: index, to: index + file.size)

              part1_rec(rest, frees, Start, index + file.size, res + checksum)
            }
            order.Lt -> {
              let res = file.id * sum(from: index, to: index + file.size)

              part1_rec(
                rest,
                [free - file.size, ..frees],
                End,
                index + file.size,
                res + checksum,
              )
            }
            order.Gt -> {
              let res = file.id * sum(from: index, to: index + free)

              part1_rec(
                deque.push_back(rest, File(file.id, file.size - free)),
                frees,
                Start,
                index + free,
                res + checksum,
              )
            }
          }
        _, _ -> checksum
      }
    }
  }
}

fn sum(from from: Int, to to: Int) -> Int {
  { { { to - 1 } * to } - { { from - 1 } * from } } / 2
}

fn part1(files: List(File), frees: List(Int)) -> Int {
  let files = deque.from_list(files)
  part1_rec(files, frees, Start, 0, 0)
}

type Block {
  File2(id: Int, size: Int)
  Free(size: Int)
}

fn find_map(
  list: List(a),
  pred: fn(a) -> Bool,
  flat_map: fn(a, Bool) -> List(a),
  found: Bool,
) -> List(a) {
  case list {
    [] -> list
    [x, ..xs] ->
      case pred(x) {
        True ->
          list.append(flat_map(x, found), find_map(xs, pred, flat_map, True))
        False -> [x, ..find_map(xs, pred, flat_map, found)]
      }
  }
}

fn part2_rec(blocks: List(Block), blocks_rev: List(Block)) -> List(Block) {
  case blocks_rev {
    [Free(_), ..rest] -> part2_rec(blocks, rest)
    [File2(id, size), ..rest] -> {
      let blocks =
        find_map(
          blocks,
          fn(block) {
            case block {
              Free(free) -> free >= size
              File2(_, _) -> block.id == id && block.size == size
            }
          },
          fn(block, found) {
            case block {
              Free(free) if !found ->
                case int.compare(size, free) {
                  order.Eq -> [File2(id, size)]
                  order.Lt -> [File2(id, size), Free(free - size)]
                  _ -> panic
                }
              File2(_, size) if found -> [Free(size)]
              _ -> [block]
            }
          },
          False,
        )
      // |> squash_frees

      part2_rec(blocks, rest)
    }
    _ -> blocks
  }
}

fn part2(blocks: List(Int)) -> Int {
  let blocks =
    list.index_map(blocks, fn(block, i) {
      case i % 2 == 0 {
        True -> File2(id: i / 2, size: block)
        False -> Free(size: block)
      }
    })

  let blocks_rev = list.reverse(blocks)

  let final_blocks = part2_rec(blocks, blocks_rev)

  list.fold(final_blocks, #(0, 0), fn(acc, block) {
    let #(index, checksum) = acc
    case block {
      Free(size) -> #(index + size, checksum)
      File2(id, size) -> #(
        index + size,
        checksum + { id * sum(from: index, to: index + size) },
      )
    }
  }).1
}

pub fn main() {
  let lines = read_file("./input.txt")
  let blocks =
    string.split(lines, "")
    |> list.map(to_int)

  let #(files, free) =
    list.index_map(blocks, fn(x, i) { #(i, x) })
    |> list.partition(fn(x) { int.is_even(x.0) })

  let files =
    list.map(files, pair.second)
    |> list.index_map(fn(x, i) { File(id: i, size: x) })

  let free = list.map(free, pair.second)

  part1(files, free)
  |> io.debug

  part2(blocks)
  |> io.debug

  Nil
}
