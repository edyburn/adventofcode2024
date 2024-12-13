import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

// const example = "Button A: X+94, Y+34
// Button B: X+22, Y+67
// Prize: X=8400, Y=5400
//
// Button A: X+26, Y+66
// Button B: X+67, Y+21
// Prize: X=12748, Y=12176
//
// Button A: X+17, Y+86
// Button B: X+84, Y+37
// Prize: X=7870, Y=6450
//
// Button A: X+69, Y+23
// Button B: X+27, Y+71
// Prize: X=18641, Y=10279
// "

type Machine {
  Machine(a: #(Int, Int), b: #(Int, Int), prize: #(Int, Int))
}

fn parse_line(config: String) {
  let assert Ok(re) = regexp.from_string("X.(\\d+), Y.(\\d+)")
  case regexp.scan(re, config) {
    [regexp.Match(_, [Some(x), Some(y)])] -> {
      let assert Ok(x) = int.parse(x)
      let assert Ok(y) = int.parse(y)
      #(x, y)
    }
    _ -> panic
  }
}

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("\n\n")
  |> list.map(fn(machine_config) {
    let assert [a_config, b_config, prize_config] =
      string.split(machine_config, "\n")
    Machine(
      parse_line(a_config),
      parse_line(b_config),
      parse_line(prize_config),
    )
  })
}

// a * a_x + b * b_x = p_x
// a * a_y + b * b_y = p_y
// minimize a * 3 + b * 1 (just one more possible solution besides a=0 and b=0?)
// a = (p_y - b * b_y) / a_y
// (a_x / a_y) * (p_y - b * b_y) + b * b_x = p_x
// b * (b_x - b_y * (a_x / a_y)) = p_x - p_y * (a_x / a_y)
// b = (p_x - p_y * (a_x / a_y)) / (b_x - b_y * (a_x / a_y))

fn check_solution(a: Int, b: Int, machine: Machine) {
  let x = machine.a.0 * a + machine.b.0 * b
  let y = machine.a.1 * a + machine.b.1 * b
  case x == machine.prize.0 && y == machine.prize.1 {
    True -> Ok(#(a, b))
    False -> Error(Nil)
  }
}

fn get_machine_solution(machine: Machine) {
  let a_x = int.to_float(machine.a.0)
  let a_y = int.to_float(machine.a.1)
  let b_x = int.to_float(machine.b.0)
  let b_y = int.to_float(machine.b.1)
  let p_x = int.to_float(machine.prize.0)
  let p_y = int.to_float(machine.prize.1)
  let b =
    { p_x -. { p_y *. { a_x /. a_y } } } /. { b_x -. { b_y *. { a_x /. a_y } } }
  let a = {
    { p_y -. { b *. b_y } } /. a_y
  }

  #(float.round(a), float.round(b))
}

fn get_machine_min_tokens(machine: Machine) {
  [
    #(machine.prize.0 / machine.a.0, 0),
    #(0, machine.prize.0 / machine.b.0),
    get_machine_solution(machine),
  ]
  |> list.map(fn(solution) { check_solution(solution.0, solution.1, machine) })
  |> result.values
  |> list.map(fn(solution) { solution.0 * 3 + solution.1 })
  |> list.sort(int.compare)
  |> list.first
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day13"))

  let machines = parse_input(input)
  let tokens_p1 =
    machines
    |> list.map(get_machine_min_tokens)
    |> result.values
    |> int.sum

  io.println("Fewest tokens to win all (part 1): " <> int.to_string(tokens_p1))

  let extra_offset = 10_000_000_000_000
  let machines =
    list.map(machines, fn(m) {
      Machine(..m, prize: #(m.prize.0 + extra_offset, m.prize.1 + extra_offset))
    })
  let tokens_p2 =
    machines
    |> list.map(get_machine_min_tokens)
    |> result.values
    |> int.sum

  io.println("Fewest tokens to win all (part 2): " <> int.to_string(tokens_p2))

  Ok(Nil)
}
