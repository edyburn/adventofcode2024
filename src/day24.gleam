import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import rememo/memo
import simplifile

const example1 = "x00: 1
x01: 1
x02: 1
y00: 0
y01: 1
y02: 0

x00 AND y00 -> z00
x01 XOR y01 -> z01
x02 OR y02 -> z02
"

const example2 = "x00: 1
x01: 0
x02: 1
x03: 1
x04: 0
y00: 1
y01: 1
y02: 1
y03: 1
y04: 1

ntg XOR fgs -> mjb
y02 OR x01 -> tnw
kwq OR kpj -> z05
x00 OR x03 -> fst
tgd XOR rvg -> z01
vdt OR tnw -> bfw
bfw AND frj -> z10
ffh OR nrd -> bqk
y00 AND y03 -> djm
y03 OR y00 -> psh
bqk OR frj -> z08
tnw OR fst -> frj
gnj AND tgd -> z11
bfw XOR mjb -> z00
x03 OR x00 -> vdt
gnj AND wpb -> z02
x04 AND y00 -> kjc
djm OR pbm -> qhw
nrd AND vdt -> hwm
kjc AND fst -> rvg
y04 OR y02 -> fgs
y01 AND x02 -> pbm
ntg OR kjc -> kwq
psh XOR fgs -> tgd
qhw XOR tgd -> z09
pbm OR djm -> kpj
x03 XOR y03 -> ffh
x00 XOR y04 -> ntg
bfw OR bqk -> z06
nrd XOR fgs -> wpb
frj XOR qhw -> z04
bqk OR frj -> z07
y03 OR x01 -> nrd
hwm AND bqk -> z03
tgd XOR rvg -> z12
tnw OR pbm -> gnj
"

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

fn get_value(id: String, sources: Dict(String, Source), cache) {
  use <- memo.memoize(cache, #(id, sources))
  let assert Ok(source) = dict.get(sources, id)
  case source {
    ConstantSource(v) -> v
    GateSource(op, left, right) -> {
      let left_val = get_value(left, sources, cache)
      let right_val = get_value(right, sources, cache)
      case op {
        AND -> left_val && right_val
        OR -> left_val || right_val
        XOR -> bool.exclusive_or(left_val, right_val)
      }
    }
  }
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day24"))

  let source_map = parse_input(input)
  use cache <- memo.create()

  let assert Ok(num_output) =
    source_map
    |> dict.keys
    |> list.filter(string.starts_with(_, "z"))
    |> list.sort(string.compare)
    |> list.reverse
    |> list.map(fn(id) { get_value(id, source_map, cache) |> bool.to_int })
    |> int.undigits(2)

  io.println("Decimal number from z wires: " <> int.to_string(num_output))

  Ok(Nil)
}
