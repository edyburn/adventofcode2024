import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

// const example = "#####
// .####
// .####
// .####
// .#.#.
// .#...
// .....

// #####
// ##.##
// .#.##
// ...##
// ...#.
// ...#.
// .....

// .....
// #....
// #....
// #...#
// #.#.#
// #.###
// #####

// .....
// .....
// #.#..
// ###..
// ###.#
// ###.#
// #####

// .....
// .....
// .....
// #....
// #.#..
// #.#.#
// #####
// "

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("\n\n")
  |> list.fold(#([], []), fn(acc, chunk) {
    let assert [head, ..lines] = string.split(chunk, "\n")
    // Discard last line (should be redundant with head)
    let heights =
      list.take(lines, 5)
      |> list.map(string.split(_, ""))
      |> list.transpose
      |> list.map(list.count(_, fn(c) { c == "#" }))
    case head {
      // Lock
      "#####" -> #([heights, ..acc.0], acc.1)
      // Key
      "....." -> #(acc.0, [heights, ..acc.1])
      _ -> panic
    }
  })
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day25"))

  let #(locks, keys) = parse_input(input)

  let valid_pairs =
    locks
    |> list.flat_map(fn(lock) {
      list.map(keys, fn(key) {
        list.zip(lock, key)
        |> list.fold_until(True, fn(_, p) {
          case p.0 + p.1 <= 5 {
            True -> list.Continue(True)
            False -> list.Stop(False)
          }
        })
      })
    })
    |> list.count(function.identity)

  io.println("Valid lock/key pairs: " <> int.to_string(valid_pairs))

  Ok(Nil)
}
