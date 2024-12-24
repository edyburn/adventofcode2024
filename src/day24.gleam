import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pair
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

type GateType {
  AND
  OR
  XOR
}

type Source {
  ConstantSource(Bool)
  GateSource(op: GateType, left: String, right: String)
}

fn parse_input(input: String) {
  let assert Ok(gate_re) =
    regexp.from_string("(\\w+) (AND|OR|XOR) (\\w+) -> (\\w+)")
  let assert [raw_values, raw_gates] =
    input |> string.trim_end |> string.split("\n\n")
  let values =
    raw_values
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [id, val] = string.split(line, ": ")
      let b = case val {
        "1" -> True
        "0" -> False
        _ -> panic
      }
      #(id, ConstantSource(b))
    })
  let gates =
    raw_gates
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [match] = regexp.scan(gate_re, line)
      let assert [Some(left), Some(op), Some(right), Some(dest)] =
        match.submatches
      let op = case op {
        "AND" -> AND
        "OR" -> OR
        "XOR" -> XOR
        _ -> panic
      }
      #(dest, GateSource(op, left, right))
    })
  dict.from_list(list.append(values, gates))
}

fn get_value(id: String, sources: Dict(String, Source)) {
  let assert Ok(source) = dict.get(sources, id)
  case source {
    ConstantSource(v) -> v
    GateSource(op, left, right) -> {
      let left_val = get_value(left, sources)
      let right_val = get_value(right, sources)
      case op {
        AND -> left_val && right_val
        OR -> left_val || right_val
        XOR -> bool.exclusive_or(left_val, right_val)
      }
    }
  }
}

fn get_digits_for_prefix(prefix: String, sources: Dict(String, Source)) {
  sources
  |> dict.keys
  |> list.filter(string.starts_with(_, prefix))
  |> list.sort(string.compare)
  |> list.reverse
  |> list.map(fn(id) { get_value(id, sources) |> bool.to_int })
}

fn binary_digits_to_decimal(digits: List(Int)) {
  digits
  |> int.undigits(2)
  |> result.lazy_unwrap(fn() { panic })
}

type Op {
  InputOp(id: String)
  BinaryOp(op: GateType, args: Set(Op))
}

fn source_to_op(id: String, sources: Dict(String, Source)) {
  let assert Ok(source) = dict.get(sources, id)
  case source {
    ConstantSource(_) -> InputOp(id)
    GateSource(op, left, right) -> {
      let left_val = source_to_op(left, sources)
      let right_val = source_to_op(right, sources)
      BinaryOp(op, set.from_list([left_val, right_val]))
    }
  }
}

fn get_inputs(op: Op, acc: Set(String)) {
  case op {
    InputOp(id) -> set.insert(acc, id)
    BinaryOp(_, args) ->
      set.fold(args, acc, fn(inputs, arg) {
        set.union(inputs, get_inputs(arg, inputs))
      })
  }
}

fn make_id(letter: String, n: Int) {
  letter <> string.pad_start(int.to_string(n), 2, "0")
}

fn make_input_op(gate: GateType, n: Int) {
  BinaryOp(
    gate,
    set.from_list([InputOp(make_id("x", n)), InputOp(make_id("y", n))]),
  )
}

fn make_expected_op(n: Int, overflow: Bool) {
  case overflow, n {
    False, 0 -> make_input_op(XOR, n)
    True, 0 -> make_input_op(AND, n)
    False, _ ->
      BinaryOp(
        XOR,
        set.from_list([make_input_op(XOR, n), make_expected_op(n - 1, True)]),
      )
    True, _ ->
      BinaryOp(
        OR,
        set.from_list([
          BinaryOp(
            AND,
            set.from_list([make_input_op(XOR, n), make_expected_op(n - 1, True)]),
          ),
          make_input_op(AND, n),
        ]),
      )
  }
}

fn check_args(left, right, exp_args, sources, neither) {
  let assert [exp_a, exp_b] = set.to_list(exp_args)
  let la = check_id(left, sources, exp_a)
  let rb = check_id(right, sources, exp_b)
  let lb = check_id(left, sources, exp_b)
  let ra = check_id(right, sources, exp_a)
  case la, rb, lb, ra {
    Ok(l), Ok(r), _, _ | _, _, Ok(l), Ok(r) -> Ok(set.from_list([l, r]))
    Ok(_), Error(r), _, _ | _, _, Ok(_), Error(r) -> Error(r)
    Error(l), Ok(_), _, _ | _, _, Error(l), Ok(_) -> Error(l)
    _, _, _, _ -> Error(neither)
  }
}

fn check_id(id: String, sources: Dict(String, Source), op: Op) {
  let assert Ok(source) = dict.get(sources, id)
  case source, op {
    ConstantSource(_), _ -> Ok(InputOp(id))
    GateSource(act_op, left, right), BinaryOp(exp_op, exp_args) -> {
      use args <- result.try(
        check_args(left, right, exp_args, sources, #(id, op)),
      )
      case act_op == exp_op && args == exp_args {
        True -> Ok(op)
        False -> Error(#(id, op))
      }
    }
    GateSource(..), _ -> Error(#(id, op))
  }
}

fn swap(sources: Dict(String, Source), a_id, b_id, swaps) {
  let assert Ok(a_val) = dict.get(sources, a_id)
  let assert Ok(b_val) = dict.get(sources, b_id)
  let new_sources =
    sources |> dict.insert(a_id, b_val) |> dict.insert(b_id, a_val)
  let new_swaps = list.append(swaps, [a_id, b_id])
  #(new_sources, new_swaps)
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day24"))

  let source_map = parse_input(input)

  let num_output =
    get_digits_for_prefix("z", source_map) |> binary_digits_to_decimal

  io.println("Decimal number from z wires: " <> int.to_string(num_output))

  let swaps =
    source_map
    |> dict.keys
    |> list.filter(string.starts_with(_, "z"))
    |> list.sort(string.compare)
    |> list.fold(#(source_map, []), fn(acc, z_id) {
      let #(sources, swaps) = acc
      let n =
        string.replace(z_id, "z", "")
        |> int.parse
        |> result.unwrap(0)
      let expected_op = make_expected_op(n, False)
      case check_id(z_id, sources, expected_op) {
        Ok(_) -> acc
        Error(#(id, op)) -> {
          let match =
            sources
            |> dict.to_list
            |> list.find(fn(entry) { source_to_op(entry.0, sources) == op })
          case match {
            Ok(#(replacement, _)) -> swap(sources, id, replacement, swaps)
            Error(..) -> acc
          }
        }
      }
    })
    |> pair.second
    |> list.sort(string.compare)
    |> string.join(",")

  io.println("Swaps: " <> swaps)

  Ok(Nil)
}
