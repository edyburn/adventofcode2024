import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import rememo/memo
import simplifile

// const example1 = "0 1 10 99 999"

// const example2 = "125 17"

fn process_stone(n: Int, i: Int, cache) {
  use <- memo.memoize(cache, #(n, i))
  let assert Ok(digits) = int.digits(n, 10)
  let len = list.length(digits)
  case i, n, len % 2 == 0 {
    0, _, _ -> 1
    _, 0, _ -> process_stone(1, i - 1, cache)
    _, _, True -> {
      let #(first, second) = list.split(digits, len / 2)
      let assert Ok(first) = int.undigits(first, 10)
      let assert Ok(second) = int.undigits(second, 10)
      process_stone(first, i - 1, cache) + process_stone(second, i - 1, cache)
    }
    _, _, _ -> process_stone(n * 2024, i - 1, cache)
  }
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day11"))

  let stones =
    input
    |> string.trim_end
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.values

  use cache <- memo.create()

  let after_25 =
    stones
    |> list.map(process_stone(_, 25, cache))
    |> int.sum

  io.println("Stones after 25 blinks: " <> int.to_string(after_25))

  let after_75 =
    stones
    |> list.map(process_stone(_, 75, cache))
    |> int.sum

  io.println("Stones after 75 blinks: " <> int.to_string(after_75))

  Ok(Nil)
}
