import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import simplifile

// const example = "Register A: 2024
// Register B: 0
// Register C: 0

// Program: 0,3,5,4,3,0
// "

type Registers {
  Registers(a: Int, b: Int, c: Int)
}

type Machine {
  Machine(reg: Registers, program: List(Int), pointer: Int, output: List(Int))
}

fn panic_unwrap(r: Result(t, e)) {
  result.lazy_unwrap(r, fn() { panic })
}

fn parse_input(input: String) {
  let assert [registers, program] =
    input |> string.trim_end |> string.split("\n\n")
  let registers =
    registers
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [_, val] = string.split(line, ": ")
      int.parse(val) |> panic_unwrap
    })
    |> fn(vals) {
      let assert [a, b, c] = vals
      Registers(a, b, c)
    }
  let program = {
    let assert [_, val] = string.split(program, ": ")
    string.split(val, ",") |> list.map(fn(v) { int.parse(v) |> panic_unwrap })
  }
  Machine(reg: registers, program: program, pointer: 0, output: list.new())
}

fn combo_operand_value(operand: Int, machine: Machine) {
  case operand {
    0 | 1 | 2 | 3 -> operand
    4 -> machine.reg.a
    5 -> machine.reg.b
    6 -> machine.reg.c
    _ -> panic
  }
}

fn update_reg(reg: String, value: Int, machine: Machine) {
  let new_reg = case reg {
    "A" -> Registers(..machine.reg, a: value)
    "B" -> Registers(..machine.reg, b: value)
    "C" -> Registers(..machine.reg, c: value)
    _ -> panic
  }
  Machine(..machine, reg: new_reg)
}

fn process_instruction(machine: Machine, target: Option(List(Int))) {
  let pointer = list.drop(machine.program, machine.pointer)
  let inc_pointer_2 = fn() { Machine(..machine, pointer: machine.pointer + 2) }
  case pointer {
    [opcode, operand, ..] -> {
      // io.println(
      //   "Processing instruction: "
      //   <> int.to_string(opcode)
      //   <> ","
      //   <> int.to_string(operand),
      // )
      let res = case opcode {
        // adv - A register divided by 2^combo operand
        0 -> {
          let result =
            int.bitwise_shift_right(
              machine.reg.a,
              combo_operand_value(operand, machine),
            )
          Ok(#(update_reg("A", result, inc_pointer_2()), target))
        }
        // bxl - bitwise XOR of B register and literal operand
        1 -> {
          let result = int.bitwise_exclusive_or(machine.reg.b, operand)
          Ok(#(update_reg("B", result, inc_pointer_2()), target))
        }
        // bst - combo operand mod 8 stored to B register
        2 -> {
          let result = combo_operand_value(operand, machine) % 8
          Ok(#(update_reg("B", result, inc_pointer_2()), target))
        }
        // jnz - A register eq 0 do nothing, otherwise jump by literal operand
        3 -> {
          Ok(#(
            case machine.reg.a == 0 {
              True -> inc_pointer_2()
              False -> Machine(..machine, pointer: operand)
            },
            target,
          ))
        }
        // bxc - bitwise XOR of B and C registers, stored to B
        4 -> {
          let result = int.bitwise_exclusive_or(machine.reg.b, machine.reg.c)
          Ok(#(update_reg("B", result, inc_pointer_2()), target))
        }
        // out - output the value of combo operand mod 8
        5 -> {
          let result = combo_operand_value(operand, machine) % 8
          let output_result = fn(rest: Option(List(Int))) {
            let new_output = [result, ..machine.output]
            case list.length(new_output) > list.length(machine.program) {
              True -> Error(Nil)
              False ->
                Ok(#(Machine(..inc_pointer_2(), output: new_output), rest))
            }
          }
          case target {
            None -> output_result(target)
            Some([h, ..rest]) if h == result -> output_result(Some(rest))
            _ -> Error(Nil)
          }
        }
        // bdv - like adv but stored in B register
        6 -> {
          let result =
            int.bitwise_shift_right(
              machine.reg.a,
              combo_operand_value(operand, machine),
            )
          Ok(#(update_reg("B", result, inc_pointer_2()), target))
        }
        // cdv - like adv but stored in C register
        7 -> {
          let result =
            int.bitwise_shift_right(
              machine.reg.a,
              combo_operand_value(operand, machine),
            )
          Ok(#(update_reg("C", result, inc_pointer_2()), target))
        }
        _ -> panic
      }
      case res {
        Ok(#(new_machine, new_target)) ->
          process_instruction(new_machine, new_target)
        Error(..) -> res
      }
    }
    _ -> {
      // Halting
      Ok(#(machine, target))
    }
  }
}

fn check_outputs_program(machine: Machine) {
  let output = machine |> fn(m) { m.output } |> list.reverse
  machine.program == output
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day17"))

  let initial_machine = parse_input(input)

  let assert Ok(output) =
    initial_machine
    |> process_instruction(None)
    |> result.map(fn(r) {
      { r.0 }.output
      |> list.reverse
      |> list.map(int.to_string)
      |> string.join(",")
    })

  io.println("Program output: " <> output)

  let copy_machine =
    yielder.iterate(228_075_452, fn(i) { i + 1 })
    |> yielder.fold_until(initial_machine, fn(machine, i) {
      io.println("Checking reg A = " <> int.to_string(i))
      let new_machine = update_reg("A", i, machine)
      case process_instruction(new_machine, Some(machine.program)) {
        Ok(#(final_machine, _)) -> {
          case check_outputs_program(final_machine) {
            True -> list.Stop(new_machine)
            False -> list.Continue(new_machine)
          }
        }
        Error(..) -> list.Continue(new_machine)
      }
    })

  io.println(
    "Register A to copy program: " <> int.to_string(copy_machine.reg.a),
  )

  Ok(Nil)
}
