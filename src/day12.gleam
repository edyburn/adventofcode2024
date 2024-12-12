import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

// const example1 = "AAAA
// BBCD
// BBCC
// EEEC
// "

// const example2 = "OOOOO
// OXOXO
// OOOOO
// OXOXO
// OOOOO
// "

// const example3 = "RRRRIICCFF
// RRRRIICCCF
// VVRRRCCFFF
// VVRCCCJFFF
// VVVVCJJCFE
// VVIVCCJJEE
// VVIIICJJEE
// MIIIIIJJEE
// MIIISIJEEE
// MMMISSJEEE
// "

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("\n")
  |> list.index_map(fn(line, y) {
    string.split(line, "") |> list.index_map(fn(t, x) { #(#(x, y), t) })
  })
  |> list.flatten
  |> dict.from_list
}

fn get_adjacent(pos: #(Int, Int)) {
  [
    #(pos.0 + 1, pos.1),
    #(pos.0, pos.1 + 1),
    #(pos.0 - 1, pos.1),
    #(pos.0, pos.1 - 1),
  ]
}

fn find_region_bounds(
  pos: #(Int, Int),
  value: String,
  bounds: Set(#(Int, Int)),
  map: Dict(#(Int, Int), String),
) {
  get_adjacent(pos)
  |> list.fold(bounds, fn(acc, adjacent) {
    let new_bounds = set.insert(acc, pos)
    case set.contains(acc, adjacent) {
      True -> new_bounds
      False -> {
        case dict.get(map, adjacent) {
          Ok(v) if v == value ->
            find_region_bounds(adjacent, value, new_bounds, map)
          _ -> new_bounds
        }
      }
    }
  })
}

fn find_regions(map: Dict(#(Int, Int), String)) {
  dict.fold(map, #(set.new(), list.new()), fn(acc, pos, value) {
    let #(seen, regions) = acc
    case set.contains(seen, pos) {
      True -> acc
      False -> {
        let region = find_region_bounds(pos, value, set.new(), map)
        let new_seen = set.union(seen, region)
        #(new_seen, [region, ..regions])
      }
    }
  })
  |> pair.second
}

fn get_plot_perimeter(pos: #(Int, Int), region: Set(#(Int, Int))) {
  let adjacent = get_adjacent(pos) |> set.from_list
  set.difference(adjacent, region) |> set.size
}

fn get_plot_sides(pos: #(Int, Int), region: Set(#(Int, Int))) {
  get_adjacent(pos)
  |> list.zip(["R", "D", "L", "U"])
  |> list.filter(fn(p) { !set.contains(region, p.0) })
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day12"))

  let parsed = parse_input(input)
  let regions = find_regions(parsed)

  let total_for_perimeter =
    regions
    |> list.map(fn(region) {
      let area = set.size(region)
      let perimeter =
        region
        |> set.to_list
        |> list.map(get_plot_perimeter(_, region))
        |> int.sum
      area * perimeter
    })
    |> int.sum

  io.println(
    "Total fencing price for perimeter: " <> int.to_string(total_for_perimeter),
  )

  let total_for_sides =
    regions
    |> list.map(fn(region) {
      let area = set.size(region)
      let sides =
        region
        |> set.to_list
        |> list.flat_map(get_plot_sides(_, region))
        |> fn(segments) {
          ["R", "D", "L", "U"]
          |> list.map(fn(dir) {
            list.filter(segments, fn(s) { s.1 == dir })
            |> dict.from_list
            |> find_regions
            |> list.length
          })
          |> int.sum
        }
      area * sides
    })
    |> int.sum
  io.println(
    "Total fencing price for sides: " <> int.to_string(total_for_sides),
  )

  Ok(Nil)
}
