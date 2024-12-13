import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/regexp
import gleam/result
import gleam/string
import rememo/memo
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

fn get_position(a: Int, b: Int, machine: Machine) {
  let x = a * machine.a.0 + b * machine.b.0
  let y = a * machine.a.1 + b * machine.b.1
  #(x, y)
}

fn cmp_pair(first: #(Int, Int), second: #(Int, Int)) {
  case int.compare(first.0, second.0), int.compare(first.1, second.1) {
    order.Eq, order.Eq -> order.Eq
    order.Gt, _ | _, order.Gt -> order.Gt
    _, _ -> order.Lt
  }
}

fn push_buttons(a: Int, b: Int, tokens: Int, machine: Machine, cache) {
  use <- memo.memoize(cache, #(a, b, tokens, machine))
  let a_result = {
    let new_a = a + 1
    let new_tokens = tokens + 3
    let new_pos = get_position(new_a, b, machine)
    case cmp_pair(new_pos, machine.prize) {
      order.Eq -> Ok(new_tokens)
      order.Gt -> Error(Nil)
      order.Lt -> {
        case new_a > 100 {
          True -> Error(Nil)
          False -> push_buttons(new_a, b, new_tokens, machine, cache)
        }
      }
    }
  }
  let b_result = {
    let new_b = b + 1
    let new_tokens = tokens + 1
    let new_pos = get_position(a, new_b, machine)
    case cmp_pair(new_pos, machine.prize) {
      order.Eq -> Ok(new_tokens)
      order.Gt -> Error(Nil)
      order.Lt -> {
        case new_b > 100 {
          True -> Error(Nil)
          False -> push_buttons(a, new_b, new_tokens, machine, cache)
        }
      }
    }
  }
  case a_result, b_result {
    Ok(a), Ok(b) if a < b -> Ok(a)
    Ok(a), Ok(b) -> Ok(b)
    Ok(a), Error(..) -> Ok(a)
    Error(..), Ok(b) -> Ok(b)
    Error(..), Error(..) -> Error(Nil)
  }
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day13"))
  use cache <- memo.create()

  let tokens =
    parse_input(input)
    |> list.map(push_buttons(0, 0, 0, _, cache))
    |> result.values
    |> int.sum

  io.println("Fewest tokens to win all: " <> int.to_string(tokens))

  Ok(Nil)
}
