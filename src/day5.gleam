import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

// const example_input = "47|53
// 97|13
// 97|61
// 97|47
// 75|29
// 61|13
// 75|53
// 29|13
// 97|29
// 53|29
// 61|53
// 97|53
// 61|29
// 47|13
// 75|47
// 97|75
// 47|61
// 75|61
// 47|29
// 75|13
// 53|13
//
// 75,47,61,53,29
// 97,61,53,29,13
// 75,29,13
// 75,97,47,61,53
// 61,13,29
// 97,13,75,29,47
// "

type Rules =
  List(#(Int, Int))

type Update =
  List(Int)

fn parse_input(input: String) {
  let #(raw_rules, raw_updates) =
    string.split(input, "\n") |> list.split_while(fn(line) { line != "" })
  let rules =
    raw_rules
    |> list.map(fn(rule) {
      let assert [before, after] = string.split(rule, "|")
      let assert Ok(before) = int.parse(before)
      let assert Ok(after) = int.parse(after)
      #(before, after)
    })
  let updates =
    raw_updates
    |> list.filter(fn(u) { u != "" })
    |> list.map(fn(u) {
      string.split(u, ",") |> list.map(int.parse) |> result.values
    })
  #(rules, updates)
}

fn check_ordering(update: Update, rules: Rules) {
  check_ordering_loop(update, rules, set.new())
}

fn check_ordering_loop(update: Update, rules: Rules, seen: Set(Int)) {
  case update {
    [i, ..rest] -> {
      let pages_after =
        rules
        |> list.filter_map(fn(rule) {
          case rule.0 == i {
            True -> Ok(rule.1)
            False -> Error(Nil)
          }
        })
        |> set.from_list
      let overlap = set.intersection(seen, pages_after) |> set.size
      case overlap == 0 {
        True -> check_ordering_loop(rest, rules, set.insert(seen, i))
        False -> False
      }
    }
    [] -> True
  }
}

fn get_middle_page(update: Update) {
  update
  // Int division is truncated, so this should drop just before the midpoint
  |> list.drop(list.length(update) / 2)
  |> list.first
  |> result.unwrap(-1)
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day5")
    |> result.replace_error("Failed to read input file"),
  )

  let sum =
    input
    |> parse_input
    |> fn(data) {
      let #(rules, updates) = data
      updates
      |> list.map(fn(update) {
        case check_ordering(update, rules) {
          True -> get_middle_page(update)
          False -> 0
        }
      })
      |> int.sum
    }

  io.println("Sum of middle pages from correct updates: " <> int.to_string(sum))

  Ok(Nil)
}
