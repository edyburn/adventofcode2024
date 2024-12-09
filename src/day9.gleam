import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

// const example_input = "2333133121414131402\n"

type Block {
  File(Int)
  Free
}

type Disk =
  List(#(Int, Block))

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("")
  |> list.map(int.parse)
  |> result.values
  |> list.fold(#(#(0, 0, True), []), fn(acc, n) {
    let #(#(index, file_id, is_file), disk) = acc
    let new_index = index + n
    let range = case n {
      // list.range is inclusive, so need to special case n = 0
      0 -> []
      _ -> list.range(index, new_index - 1)
    }
    case is_file {
      True -> {
        let new_disk =
          range
          |> list.map(fn(i) { #(i, File(file_id)) })
          |> list.append(disk, _)
        #(#(new_index, file_id + 1, False), new_disk)
      }
      False -> {
        let new_disk =
          range
          |> list.map(fn(i) { #(i, Free) })
          |> list.append(disk, _)
        #(#(new_index, file_id, True), new_disk)
      }
    }
  })
  |> pair.second
}

fn compact_files(disk: Disk) {
  let #(file_blocks, free_blocks) =
    list.partition(disk, fn(b) {
      case b.1 {
        File(_) -> True
        Free -> False
      }
    })
  // Zipping will lose items if there are more file blocks than free blocks, so
  // capture the extra file blocks
  let unmoved =
    list.take(file_blocks, list.length(file_blocks) - list.length(free_blocks))
  let moved =
    list.zip(list.reverse(file_blocks), free_blocks)
    |> list.map(fn(zipped) {
      let #(#(file_index, file), #(free_index, _)) = zipped
      case file_index > free_index {
        True -> #(free_index, file)
        False -> #(file_index, file)
      }
    })
  // Free space is ignored in the checksum, so it can be omitted
  list.append(unmoved, moved)
  // |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
}

fn compute_checksum(disk: Disk) {
  disk
  |> list.map(fn(entry) {
    let #(index, block) = entry
    case block {
      File(id) -> index * id
      Free -> 0
    }
  })
  |> int.sum
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day9")
    |> result.replace_error("Failed to read input file"),
  )

  let checksum =
    input
    |> parse_input
    |> compact_files
    |> compute_checksum

  io.println("Checksum: " <> int.to_string(checksum))

  Ok(Nil)
}
