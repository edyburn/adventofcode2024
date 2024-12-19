import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import rememo/memo
import simplifile

// const example = "r, wr, b, g, bwu, rb, gb, br

// brwrr
// bggr
// gbbr
// rrbgbr
// ubwu
// bwurrg
// brgr
// bbrgwb
// "

fn parse_input(input: String) {
  let assert [patterns, designs] =
    input |> string.trim_end |> string.split("\n\n")
  let patterns =
    string.split(patterns, ", ")
    |> list.sort(fn(a, b) { int.compare(string.length(a), string.length(b)) })
    |> list.reverse
  let designs = string.split(designs, "\n")
  #(patterns, designs)
}

fn try_design(design: String, patterns: List(String), cache) {
  use <- memo.memoize(cache, design)
  list.map(patterns, fn(pattern) {
    case string.starts_with(design, pattern) {
      True -> {
        let new_design = string.drop_start(design, string.length(pattern))
        case new_design {
          "" -> 1
          _ -> try_design(new_design, patterns, cache)
        }
      }
      False -> 0
    }
  })
  |> int.sum
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day19"))

  let #(patterns, designs) = parse_input(input)

  use cache <- memo.create()
  let design_arrangements = list.map(designs, try_design(_, patterns, cache))
  let possible_designs =
    list.filter(design_arrangements, fn(a) { a > 0 }) |> list.length
  io.println("Possible designs: " <> int.to_string(possible_designs))

  io.println(
    "Ways to make designs: " <> int.to_string(int.sum(design_arrangements)),
  )

  Ok(Nil)
}
