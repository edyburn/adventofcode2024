import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

// const example1 = "0123
// 1234
// 8765
// 9876
// "

// const example2 = "89010123
// 78121874
// 87430965
// 96549874
// 45678903
// 32019012
// 01329801
// 10456732
// "

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("\n")
  |> list.index_map(fn(line, y) {
    line
    |> string.split("")
    |> list.index_map(fn(h, x) {
      let assert Ok(h) = int.parse(h)
      #(#(x, y), h)
    })
  })
  |> list.flatten
  |> dict.from_list
}

fn find_trailheads(map: Dict(#(Int, Int), Int)) {
  map |> dict.filter(fn(_, h) { h == 0 }) |> dict.keys
}

fn get_adjacent(pos: #(Int, Int)) {
  [
    #(pos.0 + 1, pos.1),
    #(pos.0, pos.1 + 1),
    #(pos.0 - 1, pos.1),
    #(pos.0, pos.1 - 1),
  ]
}

fn find_trails(
  pos: #(Int, Int),
  target: Int,
  path: List(#(Int, Int)),
  map: Dict(#(Int, Int), Int),
) {
  use current <- result.try(dict.get(map, pos))
  let new_path = [pos, ..path]
  case current, current == target {
    // Reached the trail end
    9, True -> Ok([new_path])
    // Is correct height, so check adjacent unvisited positions
    _, True -> {
      get_adjacent(pos)
      |> list.filter(fn(p) { !list.contains(new_path, p) })
      |> list.map(find_trails(_, target + 1, new_path, map))
      |> result.values
      |> list.flatten
      |> fn(paths) {
        case list.length(paths) {
          0 -> Error(Nil)
          _ -> Ok(paths)
        }
      }
    }
    // Is incorrect height, so error
    _, _ -> Error(Nil)
  }
}

fn score_trailhead(trails: List(List(#(Int, Int)))) {
  trails |> list.map(list.first) |> list.unique |> list.length
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day10")
    |> result.replace_error("Failed to read input file"),
  )

  let map = input |> parse_input
  let sum =
    find_trailheads(map)
    |> list.map(find_trails(_, 0, [], map))
    |> result.values
    |> list.map(score_trailhead)
    |> int.sum

  io.println("Sum of trailhead scores: " <> int.to_string(sum))

  Ok(Nil)
}
