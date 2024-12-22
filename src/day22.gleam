import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

// const example = "1
// 10
// 100
// 2024
// "

fn parse_input(input: String) {
  string.trim_end(input)
  |> string.split("\n")
  |> list.map(int.parse)
  |> result.values
}

fn prune(n: Int) {
  int.bitwise_and(n, 0xFFFFFF)
}

fn next_secret(secret: Int, _) {
  let phase1 =
    int.bitwise_shift_left(secret, 6)
    |> int.bitwise_exclusive_or(secret)
    |> prune
  let phase2 =
    int.bitwise_shift_right(phase1, 5)
    |> int.bitwise_exclusive_or(phase1)
    |> prune
  let phase3 =
    int.bitwise_shift_left(phase2, 11)
    |> int.bitwise_exclusive_or(phase2)
    |> prune
  phase3
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day22"))

  let initial_numbers = parse_input(input)

  let sum =
    list.map(initial_numbers, fn(initial) {
      list.range(0, 2000 - 1) |> list.fold(initial, next_secret)
    })
    |> int.sum

  io.println("Sum of 2000th secret numbers: " <> int.to_string(sum))

  Ok(Nil)
}
