import gleam/dict.{type Dict}
import gleam/erlang
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp.{Match}
import gleam/result
import gleam/string
import gleam/yielder
import simplifile

// const example = "p=0,4 v=3,-3
// p=6,3 v=-1,-3
// p=10,3 v=-1,2
// p=2,0 v=2,-1
// p=0,0 v=1,3
// p=3,0 v=-2,-2
// p=7,6 v=-1,-3
// p=3,0 v=-1,-2
// p=9,3 v=2,3
// p=7,3 v=-1,2
// p=2,4 v=2,-3
// p=9,5 v=-3,-3
// "

// const example_dimensions = #(11, 7)

type Robot {
  Robot(pos: #(Int, Int), vel: #(Int, Int))
}

fn parse_input(input: String) {
  let assert Ok(re) = regexp.from_string("p=(\\d+),(\\d+) v=(-?\\d+),(-?\\d+)")
  input
  |> string.trim_end
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert [Match(_, matches)] = regexp.scan(re, line)
    let assert [px, py, vx, vy] =
      matches |> option.values |> list.map(int.parse) |> result.values
    Robot(#(px, py), #(vx, vy))
  })
}

fn constrain(value: Int, bound: Int) {
  case value % bound {
    v if v < 0 -> {
      v + bound
    }
    v -> v
  }
}

fn simulate_robot(robot: Robot, bounds: #(Int, Int), steps: Int) {
  let x = constrain(robot.pos.0 + robot.vel.0 * steps, bounds.0)
  let y = constrain(robot.pos.1 + robot.vel.1 * steps, bounds.1)
  #(x, y)
}

fn get_safety_factor(positions: List(#(Int, Int)), bounds: #(Int, Int)) {
  let mid_x = bounds.0 / 2
  let mid_y = bounds.1 / 2

  list.group(positions, fn(pos) {
    case pos.0, pos.1 {
      x, y if x == mid_x || y == mid_y -> "Mid"
      x, y if x < mid_x && y < mid_y -> "Q1"
      x, y if x > mid_x && y < mid_y -> "Q2"
      x, y if x < mid_x && y > mid_y -> "Q3"
      _, _ -> "Q4"
    }
  })
  |> dict.drop(["Mid"])
  |> dict.values
  |> list.fold(1, fn(acc, v) { acc * list.length(v) })
}

fn group_positions(positions: List(#(Int, Int))) {
  list.group(positions, function.identity)
  |> dict.map_values(fn(_, values) { list.length(values) })
}

fn print_map(grouped: Dict(#(Int, Int), Int), bounds: #(Int, Int)) {
  list.each(list.range(0, bounds.1 - 1), fn(y) {
    list.each(list.range(0, bounds.0 - 1), fn(x) {
      io.print(case dict.get(grouped, #(x, y)) {
        Ok(count) -> int.to_string(count)
        Error(..) -> " "
      })
    })
    io.print("\n")
  })
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day14"))
  let input_dimensions = #(101, 103)

  let robots = parse_input(input)
  let dimensions = input_dimensions

  let safety_factor_100 =
    robots
    |> list.map(simulate_robot(_, dimensions, 100))
    |> get_safety_factor(dimensions)

  io.println("Safety factor after 100s: " <> int.to_string(safety_factor_100))

  yielder.iterate(0, fn(i) { i + 1 })
  |> yielder.fold_until(Nil, fn(_, i) {
    let positions = list.map(robots, simulate_robot(_, dimensions, i))
    let grouped = group_positions(positions)
    case dict.values(grouped) |> list.all(fn(v) { v == 1 }) {
      True -> {
        io.println("Iteration " <> int.to_string(i))
        print_map(grouped, dimensions)
        case erlang.get_line("Stop? (y to exit): ") {
          Ok("y\n") -> list.Stop(Nil)
          _ -> list.Continue(Nil)
        }
      }
      False -> list.Continue(Nil)
    }
  })

  Ok(Nil)
}
