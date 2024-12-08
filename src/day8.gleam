import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

// const example_input = "............
// ........0...
// .....0......
// .......0....
// ....0.......
// ......A.....
// ............
// ............
// ........A...
// .........A..
// ............
// ............
// "

fn sub_pair(a: #(Int, Int), b: #(Int, Int)) {
  #(a.0 - b.0, a.1 - b.1)
}

fn add_pair(a: #(Int, Int), b: #(Int, Int)) {
  #(a.0 + b.0, a.1 + b.1)
}

fn get_antinodes(positions: List(#(Int, Int))) {
  positions
  |> list.combination_pairs
  |> list.map(fn(p) {
    let #(a, b) = p
    let diff = sub_pair(a, b)
    [add_pair(a, diff), sub_pair(b, diff)]
  })
  |> list.flatten
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day8")
    |> result.replace_error("Failed to read input file"),
  )

  let lines = input |> string.trim_end |> string.split("\n")
  let height = list.length(lines)
  let width = list.first(lines) |> result.unwrap("") |> string.length
  let freq_position_map =
    lines
    |> list.index_fold(dict.new(), fn(acc, line, y) {
      string.split(line, "")
      |> list.index_fold(acc, fn(acc, v, x) {
        case v {
          "." -> acc
          k ->
            dict.upsert(acc, k, fn(prev) {
              case prev {
                Some(l) -> [#(x, y), ..l]
                None -> [#(x, y)]
              }
            })
        }
      })
    })
  let unique_antinodes =
    freq_position_map
    |> dict.values
    |> list.map(get_antinodes)
    |> list.flatten
    |> list.unique
    |> list.filter(fn(coord) {
      coord.0 >= 0 && coord.0 < width && coord.1 >= 0 && coord.1 < height
    })
    |> list.length

  io.println("Unique antinodes: " <> int.to_string(unique_antinodes))

  Ok(Nil)
}
