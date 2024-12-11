import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

// const example1 = "0 1 10 99 999"

// const example2 = "125 17"

fn process_stone(n: Int) {
  let s = int.to_string(n)
  let len = string.length(s)
  case n, len % 2 == 0 {
    0, _ -> [1]
    _, True -> {
      let mid =
        int.power(10, int.to_float(len / 2))
        |> result.lazy_unwrap(fn() { panic })
        |> float.round
      [n / mid, n % mid]
    }
    _, _ -> [n * 2024]
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
  let after_25 =
    list.range(1, 25)
    |> list.fold(stones, fn(stones, _) { list.flat_map(stones, process_stone) })
    |> list.length

  io.println("Stones after 25 blinks: " <> int.to_string(after_25))

  Ok(Nil)
}
